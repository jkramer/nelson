
package Nelson::Plugin::ShortURL;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use WWW::Mechanize;
use URI;


sub namespace { 'shorturl' }


sub priority { 1001 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	$self->{username} = $cfg{username};
	$self->{password} = $cfg{password};
}


sub message {
	my ($self, $message) = @_;

	if($message->text =~ m#^!short\s+(\S+)?\s?(https?://\S+)#i) {
		my $url = new URI('http://nop.li/yourls-api.php');

		my $longurl = $2;
		my $custom  = $1;

		if(defined($custom)) {
			
			$url->query_form(
				action   => 'shorturl',
				url      => $longurl,
				keyword  => $custom,
				username => $self->{username},
				password => $self->{password},
				format   => 'simple',
			);

		} else {
			
			$url->query_form(
				action   => 'shorturl',
				url      => $longurl,
				username => $self->{username},
				password => $self->{password},
				format   => 'simple',
			);

		}

		my $result = $self->mechanize->get($url);

		if(defined($result) and length($result)) {
			$message->reply($self->mechanize->content);
		} else {
			$message->reply("Nop! You stink!");
		}
	}
	
	return 1;
}


sub mechanize {
    my ($self) = @_;

    $self->{_mechanize} ||= new WWW::Mechanize(autocheck => 0);

    return $self->{_mechanize};
}


1
