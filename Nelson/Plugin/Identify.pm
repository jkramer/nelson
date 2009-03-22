
package Nelson::Plugin::Identify;

use strict;
use warnings;


use base qw( Nelson::Plugin );


sub namespace { 'identify' }


sub priority { 5 }


sub startup {
	my ($self) = @_;

	$self->nelson->connection->message(
		'nickserv',
		'identify ' . $self->{password},
	);

	return 1;
}


1
