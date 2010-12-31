
package Nelson::Plugin::IsFriday;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'isitfriday' }


sub priority { 1001 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ m/^!isitfriday$/i) {
		if((localtime)[6] == 5) {
			$message->reply( 'Yes! It is friday! \o/' );
		}
		else {
			$message->reply( 'Haahaa! It\'s not friday!' );
		}

	}

	return 1;
}

1
