
package Nelson::Message;

use strict;
use warnings;

use base qw( Class::Class );

our %MEMBERS = (
	prefix     => '$',
	command    => '$',
	channel    => '$',
	text       => '$',
	connection => '$',
);

sub from {
	my ($self) = @_;

	if($self->prefix and $self->prefix =~ /^([^ !]+)(.*)/i) {
		return $1;
	}

	return undef;
}


sub host {
	my ($self) = @_;

	if($self->prefix and $self->prefix =~ /^([^ !]+)(.*)/i) {
		return $2;
	}

	return undef;
}


sub reply {
	my ($self, $text) = @_;

	$self->send($self->from . ': ' . $text);
}


sub send {
	my ($self, $text) = @_;

	$self->connection->message($self->channel, $text);
}


1
