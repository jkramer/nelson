
package Nelson::Plugin::Twitter;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Net::Twitter;


sub namespace { 'twitter' }


sub priority { 100 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	my @keys = qw(
		consumer_key consumer_secret
		access_token access_token_secret
		channel
	);

	if(grep { !$cfg{$_} } @keys) {
		warn "Twitter configuration incomplete. Need all of @keys.\n";
		return;
	}

	$self->{twitter} = new Net::Twitter(
		consumer_key	=> $cfg{consumer_key},
		consumer_secret	=> $cfg{consumer_secret},
		traits		=> ['API::REST', 'OAuth'],
	);

	$self->{twitter}->access_token($cfg{access_token});
	$self->{twitter}->access_token_secret($cfg{access_token_secret});

	$self->{last_check} = time;
	$self->{last_mention} = '';
	$self->{channel} = $cfg{channel};
}


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!twit\s+(.+?)\s*$/) {
		my $update = $1;

		my $tag = $self->tweet($update);

		if($tag) {
			$message->reply('You suck twice as hard as ' . $tag . '.');
		}
		else {
			$message->reply('Twitter is not configured.');
		}
	}

	elsif($self->{twitter} && $message->text =~ /^!mention\s*$/) {
		$message->reply($self->last_mention);
	}

	return 1;
}


sub last_mention {
	my ($self) = @_;

	my $mention;

	eval {
		my $mentions = $self->{twitter}->mentions( { count => 1 } );
		$mention = $mentions->[0];
	};

	return "$mention->{text} (from \@$mention->{user}->{screen_name})";
}


sub ping {
	my ($self, $message) = @_;

	my $now = time;

	if($now > ($self->{last_check} + 60)) {
		my $mention = $self->last_mention;

		if($mention ne $self->{last_mention}) {
			$message->channel($self->{channel});
			$message->send('New mention: ' . $mention);

			$self->{last_mention} = $mention;
		}
	}

	$self->{last_check} = $now;

	return 1;
}


sub tweet {
	my ($self, $text) = @_;

	if($self->{twitter}) {
		my $tag = $self->_random_tag;

		if(length($text) + length($tag) >= 138) {
			$text = substr($text, 0, 140 - length($text) - length($tag) - 7) . ' [...]';
		}

		$text .= ' ' . $tag;

		$self->{twitter}->update($text);
		return $tag;
	}
	else {
		return undef;
	}
}


sub _random_tag {
	my ($self) = @_;

	my @hashtag = qw(
		loveparade android ipad itampon apple h1n1 bundestag cdu jesustweeters
		fdp spd iphone twitter merkel westerwelle berlin google
	);

	return '#' . $hashtag[int(rand(@hashtag))];
}



1
