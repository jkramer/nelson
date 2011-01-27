
package Nelson::Plugin::Invite;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'invite' }

sub priority { 100 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	$self->{channel_list} = [ split /\s*,\s*/, ($cfg{channels} || '') ];

	s/^(\W)/#$1/ for(@{$self->{channel_list}});

	return $self;
}


# Ignore everything that is not a nelson command (e.g. starts with '!').
sub invite {
	my ($self, $message) = @_;

	my $channel = $message->text;
	my @channel_list = @{$self->{channel_list}};

	if(@channel_list && grep { $_ eq $channel } @channel_list) {
		$message->connection->join($message->text);
	}

	return 1;
}


1
