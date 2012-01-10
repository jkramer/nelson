
package Nelson::Plugin::Ignore;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'ignore' }

sub priority { 1 }


# Ignore everything that is not a nelson command (e.g. starts with '!').
sub message {
	my ($self, $message) = @_;

	return $message->text =~ /^((?:\d*)!|^[a-z]+\?|.*https?:\/\/\S+.*)/;
}


1
