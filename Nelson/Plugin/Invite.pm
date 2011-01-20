
package Nelson::Plugin::Invite;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'invite' }

sub priority { 100 }


# Ignore everything that is not a nelson command (e.g. starts with '!').
sub invite {
	my ($self, $message) = @_;

	$message->connection->join($message->text);

	return 1;
}


1
