package Nelson::Plugin::Twitter;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use Net::Twitter;
use Encode;

use Nelson::Schedule;
use Nelson::Schedule::Job;


sub namespace { 'twitter' }


sub priority { 1000 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	$self->{_nelson} = $nelson;

	my @keys = qw(
		consumer_key consumer_secret
		access_token access_token_secret
		channel
	);

	if(grep { !$cfg{$_} } @keys) {
		warn "Twitter configuration incomplete. Need all of @keys.\n";
		return;
	}

	$self->{twitter} = Net::Twitter->new(
		ssl => 1,
		traits   => [qw/API::RESTv1_1/],
		consumer_key        => $cfg{consumer_key},
		consumer_secret     => $cfg{consumer_secret},
		access_token        => $cfg{access_token},
		access_token_secret => $cfg{access_token_secret},
	);

	$self->{twitter}->access_token($cfg{access_token});
	$self->{twitter}->access_token_secret($cfg{access_token_secret});

	$self->{last_mention} = '';
	$self->{channel} = $cfg{channel};

	Nelson::Schedule->instance->register(
		new Nelson::Schedule::Job(
			'twitter dms',
			20,
			sub { eval { $self->_handle_direct_messages } },
		)
	);

	Nelson::Schedule->instance->register(
		new Nelson::Schedule::Job(
			'twitter mentions',
			30,
			sub { eval { $self->_handle_mentions } },
		)
	);
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
		my $mentions = $self->{twitter}->mentions( { count => 1, since => (time - 600) } );
		$mention = $mentions->[0];
	};

	return undef unless $mention;

	return "$mention->{text} (from \@$mention->{user}->{screen_name})";
}


sub tweet {
	my ($self, $text) = @_;

	if($self->{twitter}) {
		my $tag = $self->_random_tag;

		if(length($text) + length($tag) >= 138) {
			$text = substr($text, 0, 140 - length($text) - length($tag) - 7) . ' [...]';
		}

		$text .= ' ' . $tag;

		$self->{twitter}->update(decode('UTF-8', $text));
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
		fdp spd iphone twitter merkel westerwelle berlin google aufschrei
	);

	return '#' . $hashtag[int(rand(@hashtag))];
}


sub _handle_direct_messages {
	my ($self) = @_;

	my $dm_list = $self->{twitter}->direct_messages;

	for my $dm (reverse @$dm_list) {
		my $from = $dm->{sender_screen_name};

		$self->nelson->connection->message($self->{channel}, $from . ' via DM: ' . $dm->{text});

		my $message = new Nelson::Message;

		$message->prefix($from);
		$message->command('PRIVMSG');
		$message->channel($self->{channel});
		$message->text($dm->{text});
		$message->connection($self->nelson->connection);

		$self->nelson->inject_message($message);

		$self->{twitter}->destroy_direct_message($dm->{id});
	}
}


sub _handle_mentions {
	my ($self) = @_;

	my $mention = $self->last_mention;

	if($mention && $mention ne $self->{last_mention}) {
		$self->nelson->connection->message(
			$self->{channel},
			$mention
		);

		$self->{last_mention} = $mention;
	}
}


1
