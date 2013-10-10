
package Nelson::Connection;

use strict;
use warnings;

use Class::Class;

use base qw( Class::Class );

use Nelson::IRC;
use Nelson::Message;

our %MEMBERS = (
	channel  => '$',
	host     => '$',
	port     => '$',
	nick     => '$',
	password => '$',
	irc      => 'Nelson::IRC',
	ssl      => '$',
	bind     => '$',
);


sub setup {
	my ($self, %cfg) = @_;

	for(qw( channel host port nick password bind )) {
		$self->$_($cfg{'irc.' . $_});
	}

	$self->irc(new Nelson::IRC);

	$self->irc->host($self->host);
	$self->irc->name($self->nick);
}


sub callback {
	my ($self, $event, $callback) = @_;

	$self->irc->callback(
		$event => sub {
			my (undef, $prefix, $command, $channel, $text) = @_;

			my $message = new Nelson::Message;

			$message->prefix($prefix);
			$message->command($command);
			$message->channel($channel);
			$message->text($text);
			$message->connection($self);

			&{$callback}($message);
		},
	);
}


sub connect {
	my ($self) = @_;

	$self->irc->connect(undef, undef, $self->bind || undef) or die "Failed to connect socket. $!.\n";
	$self->irc->loop;
}


sub join {
	my ($self) = @_;

	$self->irc->join($self->channel, $self->password);
}


sub message {
	my ($self, $channel, $text) = @_;

	$self->irc->message($channel, $text);
}


sub disconnect {
	my ($self, $message) = @_;

	$self->irc->quit;
}


1
