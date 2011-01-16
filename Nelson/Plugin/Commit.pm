
package Nelson::Plugin::Commit;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use WWW::Mechanize;
#use Data::Dumper;


sub namespace { 'commit' }


sub priority { 1002 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ m/^!commit\s*$/i) {

		my $url = "http://whatthecommit.com/";

		my $result = $self->mechanize->get($url);

		if(defined($result) and length($result)) {
			my $content = $self->mechanize->content;
			$content =~ s#.*<p>(.*)</p>.*#$1#gmsi;

			$message->reply($content);
		}
		else {
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
