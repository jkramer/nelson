
package Nelson::Plugin::Weather;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Weather::Google;
use encoding 'utf8';


sub namespace { 'weather' }


sub priority { 1001 }

sub message {
	my ($self, $message) = @_;
	my $grad = "°";

	$self->{_weather} ||= new Weather::Google;

	if($message->text =~ m#^!weather\s+(.+)$#i) {
		my $where = $1;

		$self->{_weather}->city($where);
		$self->{_weather}->encoding('utf-8');

		my $city = $self->{_weather}->info('city');
		my $temp_f = $self->{_weather}->current('temp_f');
		my $temp_c = sprintf('%.2f', (($temp_f - 32 ) * (5 / 9)));
		my $temp_k = ($temp_c + 273.15);
		my $cond = $self->{_weather}->current('condition') || 'Unknown';

		if(defined($city) and length($city)) {
			$message->reply(
				'The current conditions in ' . $city . ' are: ' . $cond . ' at ' . $temp_c . $grad . 'C ( '
				. $temp_f . $grad . 'F / ' . $temp_k . 'K )'
			);
		} else {
			$message->reply("Haahaa! I wasn't able to fetch the weather data!");
		}
	}
	elsif($message->text =~ m#^!fcast\s+(.+)$#i) {
		my $where = $1;

		$self->{_weather}->city( $where );
		$self->{_weather}->encoding( 'utf-8' );

		my $city = $self->{_weather}->info( 'city' );
		my ($high_f, $low_f, $day, $cond) = $self->{_weather}->forecast(1, 'high', 'low', 'day_of_week', 'condition');
		my $high_c = sprintf('%.2f', (($high_f - 32) * (5 / 9)));
		my $low_c = sprintf('%.2f', (($low_f - 32) * (5 / 9)));

		if(defined($city) and length($city)) {
			$message->reply(
				'The forcast conditions for ' . $day . ' in ' . $city . ' are: ' . $cond . ' at ' . $high_c . $grad . 'C (highest) / '
				. $low_c . $grad . 'C (lowest)'
			);
		}
		else {
			$message->reply("Haahaa! I wasn't able to fetch the weather data!");
		}

	}

	return 1;
}


1
