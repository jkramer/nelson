
package Nelson::Plugin::RFC;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use WWW::Mechanize;


sub namespace { 'rfc' }


sub priority { 1000 }


sub message {
	my ($self, $message) = @_;

	$self->{_mechanize} ||= new WWW::Mechanize ( autocheck => 0, timeout => 2 );

	if($message->text =~ m#^!rfc\s+(\d+)#) {
		my $rfc = $1;
		my $url = 'http://www.faqs.org/rfcs/rfc' . $rfc . '.html';
		my $head = $self->mechanize->head($url);
		my $size = $head->{"_headers"}->{"content-length"} || 0;
		my $type = $head->{"_headers"}->{"content-type"} || '';

		if($size > 50000 or $type !~ /^text\//) {
			return 1;
		}

		my $result = $self->mechanize->get($url);

		if(defined($result) and length($result)) {
			my $title = $self->mechanize->title;

			if($title ne 'File not found! - faqs.org') {
				$message->reply($self->mechanize->title . ' // ' . $url);
			} else {
				$message->reply('Haahaa! That RFC doesn\'t exist!');
			}
		} else {
			$message->reply("Nop! You stink!");
		}
	}

	return 1;
}


sub mechanize {
    my ($self) = @_;

    $self->{_mechanize} ||= new WWW::Mechanize;

    return $self->{_mechanize};
}


1
