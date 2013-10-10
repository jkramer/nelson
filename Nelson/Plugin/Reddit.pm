
package Nelson::Plugin::Reddit;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Reddit::Client;


sub namespace { 'reddit' }


sub priority { 999 }


sub message {
	my ($self, $message) = @_;

	$self->{client} ||= Reddit::Client->new;

	if($message->text =~ /^!aww\s*$/) {
		my $links = $self->{client}->fetch_links(subreddit => '/r/aww', limit => 50);

		my $link = $links->{items}->[int rand 50];

		$message->reply("Here's some cute shit for you: " . $link->{url});
	}
}


1
