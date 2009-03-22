
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

	$self->schema->connection(
		( map { $cfg{'database.' . $_} } qw( source user password ), ),
		{
			quote_char => '"',
			name_sep   => '.',
		}
	);

	# Load and initialize plugins.
	for my $plugin ($self->plugins) {
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

sub _message {
	my ($self, $message) = @_;

	$self->_dispatch('message', $message);
}

sub _kicked {
	my ($self, $message) = @_;

	$self->_dispatch('kicked', $message);
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
