
package Nelson::Plugin::MiniCity;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use XML::MiniCity;
use Text::Conjunct;

sub namespace { 'minicity' }


sub priority { 100 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	if($cfg{name}) {
		$self->{city} = new XML::MiniCity($cfg{name});
	}
}


sub city { $_[0]->{city} }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!city\s*$/) {
		my $city = $self->city;

		if($city) {
			$city->update;

			my @list;

			my $transport    = $city->transport;
			my $unemployment = $city->unemployment;
			my $crime        = $city->criminality;
			my $pollution    = $city->pollution;

			if(int($transport) != 100) {
				push @list, 'funky bus drivers';
			}

			if(int($unemployment) > 0 ) {
				push @list, 'work';
			}

			if(int($crime) > 0) {
				push @list, 'Mr. Monk';
			}

			if(int($pollution) > 0) {
				push @list, 'green peace';
			}

			my $need = 'Need ' . (@list ? conjunct('and', @list) : 'nothing') . '.';

			$message->reply($need);
		}

		else {
			$message->reply('MiniCity is not configured.');
		}
	}

	return 1;
}


1
