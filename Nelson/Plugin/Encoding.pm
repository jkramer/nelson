
package Nelson::Plugin::Encoding;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Encode;
use Encode::Guess;


sub namespace { 'encoding' }


# Run this first, so the other plugins get messages with fixed encoding.
sub priority { 0 }


# Try to guess encoding and decode message.
sub message {
	my ($self, $message) = @_;

	my $decoder = Encode::Guess->guess($message->text);

	if(ref($decoder)) {
		$message->text($decoder->decode($message->text));
	}

	return 1;
}


1
