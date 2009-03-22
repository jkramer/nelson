
package Nelson::Plugin::Twitter;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Net::Twitter;


sub namespace { 'twitter' }


sub priority { 100 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	if($cfg{username} and $cfg{password}) {
		$self->{twitter} = new Net::Twitter;
		$self->{twitter}->credentials($cfg{username}, $cfg{password});
	}
}


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!twit\s+(.+?)\s*$/) {
		my $update = $1;

		if($self->{twitter}) {
			$self->{twitter}->update($update);
			$message->reply('Twitter sucks hard.');
		}
		else {
			$message->reply('Twitter is not configured.');
		}
	}

	return 1;
}


1
