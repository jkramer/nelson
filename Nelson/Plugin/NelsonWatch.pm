
package Nelson::Plugin::NelsonWatch;

use strict;
use warnings;

use Mail::SendEasy;

use base qw( Nelson::Plugin );


sub namespace { 'nelsonwatch' }


sub priority { 1000 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	@{$self}{keys %cfg} = values %cfg;
}


sub quit {
	my ($self, $message) = @_;

	warn $message->from . ' <-> ' . $self->{watch_nick} . "\n";

	if($message->from eq $self->{watch_nick}) {
		my $mail = new Mail::SendEasy(
			smtp => 'localhost',
			user => $self->{mail_user},
			pass => $self->{mail_pass},
		);

		$mail->send(
			from => $self->{mail_from},
			from_title => $self->{mail_name},
			to => $self->{mail_to},
			subject => $self->{watch_nick} . ' is down - again!',
			msg => 'Fix it!',
		);
	}

	return 1;
}


1
