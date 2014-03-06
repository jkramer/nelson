
package Nelson::Plugin::Update;

use strict;
use warnings;

our @ISA = qw( Nelson::Plugin );


sub namespace { 'update' }


sub priority { 101 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!update$/) {
		my $output = qx( $self->{command} );

		if($output !~ /up-to-date/) {
			$message->reply('Found update. Restarting.');
			$self->nelson->restart;
		}
		else {
			$message->reply(q#I'm already up-to-date.#);
		}
	}

	return 1;
}


1
