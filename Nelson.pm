
package Nelson;

use strict;
use warnings;

use Carp;
use Module::Pluggable;
use Module::Load;

use Nelson::Connection;
use Nelson::Schema;
use Nelson::Schedule;

use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(
	qw(
		connection
		schema
		loaded
	)
);


sub new {
	my ($class) = @_;

	my $self = bless {}, $class;

	$self->connection(Nelson::Connection->new);
	$self->schema('Nelson::Schema');
	$self->loaded({});

	return $self;
}


sub setup {
	my ($self, %cfg) = @_;

	$self->connection->setup(%cfg);

	if($cfg{'database.source'}) {
		my $options = {};

		for(qw( quote_char name_sep )) {
			if(exists($cfg{'database.' . $_})) {
				$options->{$_} = $cfg{'database.' . $_};
			}
		}

		$options->{quote_char} = '"' unless exists($options->{quote_char});

		$self->schema->connection(
			( map { $cfg{'database.' . $_} } qw( source user password ), ),
			$options
		);
	}

	my $plugin_load_list = $cfg{'plugins.load'};
	if($plugin_load_list && !ref($plugin_load_list)) {
		$plugin_load_list = [ $plugin_load_list ];
	}

	my $plugin_ignore_list = $cfg{'plugins.ignore'};
	if($plugin_ignore_list && !ref($plugin_ignore_list)) {
		$plugin_ignore_list = [ $plugin_ignore_list ];
	}

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

		$self->loaded->{$namespace} = $instance;
	}
}


sub run {
	my ($self) = @_;

	$self->{original_0} = $0;

	$0 = 'nelson-ng [event loop]';

	# Setup callbacks.
	$self->_callback(376     => '_startup');
	$self->_callback(PRIVMSG => '_message');
	$self->_callback(KICK    => '_kicked');
	$self->_callback(QUIT    => '_quit');
	$self->_callback(PING	 => '_pinged');
	$self->_callback(INVITE  => '_invited');

	# Start.
	$self->connection->connect;

	$0 = $self->{original_0};
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

	Nelson::Schedule->instance->fork_loop;
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


sub _invited {
	my ($self, $message) = @_;

	$self->_dispatch('invite', $message);
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
		values %{$self->loaded}
	];

	for my $plugin (@$order) {
		last unless $plugin->$method($message);
	}
}


sub plugin {
	my ($self, $name) = @_;

	if(exists($self->loaded->{$name})) {
		return $self->loaded->{$name};
	}
	else {
		return undef;
	}
}


sub restart {
	my ($self) = @_;

	my @cmd = ($self->{original_0} || $0, %ARGV);

	unshift @cmd, 'perl' if($0 !~ m#(^|/)perl$#);

	Nelson::Schedule->instance->terminate;
	$self->connection->disconnect;

	exec(@cmd);
}


END {
	Nelson::Schedule->instance->terminate;
}


1
