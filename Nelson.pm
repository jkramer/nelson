
package Nelson;

use strict;
use warnings;

use Carp;
use Module::Pluggable;
use Module::Load;

use Nelson::Connection;
use Nelson::Schema;

use base qw( Class::Class );

our %MEMBERS = (
	connection => 'Nelson::Connection',
	schema     => '$',
	loaded     => '%',
);


sub initialize {
	my ($self) = @_;

	$self->connection(new Nelson::Connection);
	$self->schema('Nelson::Schema');
	$self->loaded([]);

	return $self;
}


sub setup {
	my ($self, %cfg) = @_;

	$self->connection->setup(%cfg);

	if($cfg{'database.source'}) {
		$self->schema->connection(
			( map { $cfg{'database.' . $_} } qw( source user password ), ),
			{
				quote_char => '"',
				name_sep   => '.',
			}
		);
	}

	my $plugin_load_list = $cfg{'plugins.load'};

	my $plugin_ignore_list = $cfg{'plugins.ignore'};

	# Load and initialize plugins.
	for my $plugin ($self->plugins) {

		# If "plugins.load" is available, load only plugins listed there.
		if(ref($plugin_load_list) eq 'ARRAY') {
			my $match = grep {
				$plugin eq "Nelson::Plugin::$_"
			} @$plugin_load_list;

			next unless $match;
		}

		# Otherwise, if "pluins.ignore" is available, skip plugins listed
		# there.
		elsif(ref($plugin_ignore_list) eq 'ARRAY') {
			my $match = grep {
				$plugin eq "Nelson::Plugin::$_"
			} @$plugin_ignore_list;

			next if $match;
		}

		load $plugin;

		next unless $plugin->can('namespace');

		my $instance = $plugin->new;
		my $namespace = $plugin->namespace;

		$instance->initialize(
			$self,
			map {
				/^\Q$namespace\E\.(.*)$/;
				$1 => $cfg{$_}
			}
			grep {
				/^\Q$namespace\E\./
			} keys %cfg
		);

		$self->loaded($namespace => $instance);
	}
}


sub run {
	my ($self) = @_;

	# Setup callbacks.
	$self->_callback(376     => '_startup');
	$self->_callback(PRIVMSG => '_message');
	$self->_callback(KICK    => '_kicked');
	$self->_callback(QUIT    => '_quit');
	$self->_callback(PING	 => '_pinged');

	# Start.
	$self->connection->connect;
}


sub _callback {
	my ($self, $event, $method) = @_;

	$self->connection->callback(
		$event => sub {
			my ($message) = @_;
			$self->$method($message);
		}
	);
}


sub _startup {
	my ($self, $message) = @_;

	$self->_dispatch('startup', $message);

	# Join channel.
	$self->connection->join;
}


sub inject_message {
	my ($self, $message) = @_;

	$self->_message($message);
}


sub _message {
	my ($self, $message) = @_;

	# Remove leading and trailing spaces.
	my $text = $message->text;

	$text =~ s/^\s+//;
	$text =~ s/\s+$//;

	$message->text($text);

	$self->_dispatch('message', $message);
}

sub _pinged {
	my ($self, $message) = @_;

	$self->_dispatch('ping', $message);
}

sub _kicked {
	my ($self, $message) = @_;

	$self->_dispatch('kicked', $message);
}


sub _quit {
	my ($self, $message) = @_;

	$self->_dispatch('quit', $message);
}


sub _dispatch {
	my ($self, $method, $message) = @_;

	my $order = [
		sort {
			$a->priority <=> $b->priority
		}
		grep {
			$_->can($method)
		}
		values %{ $self->loaded }
	];

	for my $plugin (@$order) {
		last unless $plugin->$method($message);
	}
}


1
