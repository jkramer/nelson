
package Nelson::Plugin::Schedule;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Nelson::Schedule;

sub namespace { 'schedule' }


sub priority { 100 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!schedule\s*$/) {
		$message->reply(
			join(
				'; ',
				map {
					$_->name . ' in ' . ($_->next - time) . 's'
				}
				Nelson::Schedule->instance->jobs
			)
		);
	}

	return 1;
}


1
