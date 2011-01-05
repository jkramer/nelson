
package Nelson::Plugin::Fefe;

use strict;
use warnings;

use XML::Feed;
use URI;
use Encode;

use base qw( Nelson::Plugin );


sub namespace { 'fefe' }


sub priority { 1001 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ m/^!fotd$/i) {
		my $feed = XML::Feed->parse(URI->new('http://blog.fefe.de/rss.xml'));

		my @introductions;
		my @followups;

		for my $entry ($feed->entries) {
			my $text = encode('utf-8', $entry->title);
			$text =~ s/([a-z])\.([A-Z])/$1. $2/g;
			my ($first, @rest) = split /(?<=[!?.])\s+|m\(|[;:X]-?[()Dp|]\s*/, $text;
			push @introductions, $first;
			push @followups, @rest;
		}

		my $n = int(rand(5)) + 1;

		my @post = $introductions[int(rand(@introductions))];

		push @post, splice(@followups, int(rand(@followups)), 1) while($n--);

		$message->reply(join(' ', @post));
	}

	return 1;
}

1
