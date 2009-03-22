
package Nelson::Plugin::Debug;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Module::Refresh;


sub namespace { 'debug' }


sub priority { 1000 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!refresh\s*$/) {
		Module::Refresh->refresh;
		$message->reply('Reloaded.');
	}

	return 1;
}


1
