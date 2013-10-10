
package Nelson::Plugin::Reddit;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use WWW::Mechanize;
use JSON;


sub namespace { 'reddit' }


sub priority { 999 }


sub message {
	my ($self, $message) = @_;

	$self->{mech} ||= WWW::Mechanize->new;

	if($message->text =~ /^!aww\s*$/) {
		$self->{mech}->get('http://www.reddit.com/r/aww/hot.json');

		my $data = from_json($self->{mech}->content);

		my $items = $data->{data}->{children};

		my $item = $items->[int rand scalar(@$items)];

		$message->reply("Here's some cute shit for you: " . $item->{data}->{url});
	}
}


1
