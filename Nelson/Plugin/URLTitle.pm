
package Nelson::Plugin::URLTitle;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use WWW::Mechanize;
use Data::Dumper;


sub namespace { 'urltitle' }


sub priority { 1000 }


sub message {
	my ($self, $message) = @_;

	$self->{_mechanize} ||= new WWW::Mechanize(
		autocheck => 0,
		timeout => 2,
		agent => 'Linux Mozilla',
	);

	if($message->text =~ m#(https?://\S+)#i and $message->text !~ m#^!short#) {
		my $url = $1;
		return 1 if $url =~ m#http://www.imdb.com/title/#i;
		my $head = $self->mechanize->head($url);
		my $size = $head->{"_headers"}->{"content-length"} || 0;
		my $type = $head->{"_headers"}->{"content-type"} || '';

		if($size > 10000 or $type !~ /^text\//) {
			return 1;
		}

		my $result = $self->mechanize->get($url);

		if(defined($result) and length($result)) {
			$message->reply($self->mechanize->title);
		} else {
			$message->reply("Nop! You stink!");
		}
	}

	return 1;
}


sub mechanize {
    my ($self) = @_;

    $self->{_mechanize} ||= new WWW::Mechanize(stack_depth => 0);

    return $self->{_mechanize};
}


1
