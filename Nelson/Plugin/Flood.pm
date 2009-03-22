
package Nelson::Plugin::Flood;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'flood' }

sub priority { 1 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	$self->{banned}  = {};
	$self->{spam}    = {};
	$self->{_nelson} = $nelson;
}


sub message {
	my ($self, $message) = @_;

	my $banned = $self->{banned};
	my $spam   = $self->{spam};
	my $host   = $message->host;

	my $continue = 1;

	if($message->text =~ /^!ban\s*$/) {
		if($banned->{$host} && $banned->{$host} > time) {
			my $left = $banned->{$host} - time;
			my $minutes = sprintf('%.1f', $left / 60.0);

			$message->reply(
				"Haahaa! Du bist ja noch für ca. $minutes gebanned!"
			);

			$continue = 0;
		}
		else {
			$message->reply('Haahaa! Du darfst mich ja benutzen!');
		}
	}


	$spam->{$host} ||= [];
	push @{$spam->{$host}}, time;

	@{$spam->{$host}} = grep {
		$_ > time - 60
	} @{$spam->{$host}};

	my $bantime = 0;

	my $five = grep { $_ > time - 5 } @{$spam->{$host}};
	my $sixty = @{$spam->{$host}};

	if($five > 3) {
		$bantime += 150;
	}

	if($sixty >= 15) {
		$bantime += 1800;
	}

	if($bantime > 0) {
		if(!$banned->{$host} || (time - $banned->{$host}) > 0) {
			$banned->{$host} = time + $bantime;

			my $minutes = sprintf('%.1f', $bantime / 60.0);
			$message->reply(
				"Haahaa! Du bist ja jetzt für ca. $minutes Minuten gebanned!"
			);
		}
		else {
			$banned->{$host} += $bantime;
		}
	}

	if($banned->{$host} and (time - $banned->{$host} < 0)) {
		$continue = 0;
	}

	return $continue;
}


1
