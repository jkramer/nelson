
package Nelson::Plugin::LMGTFY;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'lmgtfy' }


sub priority { 1001 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!google\s+(\S+)\s+(.+?)\s*$/) {
		my $target = $1;
		my $search = $2;

		$search =~ s/(\W)/sprintf('%%%02X', ord($1))/ge;

		$message->connection->message($message->channel, $target . ': http://lmgtfy.com/?q=' . $search);
	}

	return 1;
}


1
