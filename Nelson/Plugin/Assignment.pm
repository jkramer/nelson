
package Nelson::Plugin::Assignment;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'assign' }


sub priority { 101 }


sub ping {
	my ($self, $message) = @_;

	if(uc($message->{command}) eq 'PING') {
		my (undef, $min, undef) = localtime(time);

		if(!int rand 40) {
			$message->{channel} = '#dokuleser';
			$message->send('Random Nelson: ' . $self->_random_nelson);
		}
	}

	return 1;
}


sub message {
	my ($self, $message) = @_;

	my $text = $message->text;
	my $from = $message->from;

	if($text =~ /^!(?:assign|rem)\s+(.+?)\s*=\s*(.+?)\s*$/) {
		my ($key, $value) = ($1, $2);

		$message->reply($self->assign($key, $value, $message->from));
	}

	elsif($text =~ /^!forget\s+(.+?)\s*$/) {
		my $key = $1;

		my $last = $self->resolve($key);

		if($last and $last->user eq $from) {
			$last->delete;
			$message->reply('Ok.');
		}
		else {
			$message->reply('Uhm... no.');
		}
	}

	elsif($text =~ /^(\d+)?!!(.+?)\s*$/) {
		my ($revision, $key) = ($1, $2);

		$revision = undef if(defined($revision) and !length($revision));

		$message->reply($self->read($key, $revision));
	}

	elsif($text =~ /^!!\s*$/) {
		my $rand = int(rand($self->assignments->count)) + 1;
		my ($assignment) = $self->assignments->slice($rand, $rand + 1);

		$message->send($self->_format($assignment));
	}

	elsif($text =~ /^!find\s+(.+?)\s*$/) {
		$message->reply($self->find($1));
	}

	elsif($text =~ /^!nelson(?:\s+(\w+))?\s*$/) {
		my $target = $1;
		my $nelson = $self->_random_nelson;

		if(defined($target) and length($target)) {
			$message->send($target . ': ' . $nelson);
		} else {
			$message->send($nelson);
		}
	}

	elsif($text =~ /^!selfnelson\s*$/) {
		$message->reply($self->_random_nelson);
	}

	elsif($text =~ /^!ftw\s*(.*)$/) {
		my $sendto = $1;
		$message->send($sendto . ' ftw! \o/');
	}

	elsif($text =~ /^!twitson\s+(.+?)\s*$/) {
		my $nick = $1;

		$self->_tweet_nelson($message, $nick);
	}

	elsif($text =~ /^!randson\s*$/) {
		$self->_tweet_nelson($message, undef);
	}

	elsif($text =~ /^!fail\s(.+?)\s*$/) {
		my $sendto = $1;

		my $fails = $self->assignments->search(
			{ key => { -ilike => '%fail%' } },
		);

		my $rand = int(rand($fails->count)) + 1;
		my ($fail) = $fails->slice($rand, $rand + 1);

		$message->send($sendto . ': Haahaa! You failed! -> ' . $fail->value);
	}

	return 1;
}


sub assign {
	my ($self, $key, $value, $from) = @_;

	if($key =~ /nelson/i and $value !~ /^Haahaa! [A-Z0-9].*!/) {
		return "Sorry, that's not a legal Nelson.";
	}

	my $last = $self->resolve($key);

	if($last) {
		if($last->user eq $from or $last->when->epoch < (time - (2 * 360))) {
			$self->assignments->create(
				{
					user => $from,
					key => $key,
					value => $value,
					revision => $last->revision + 1,
				}
			);

			return "Thanks for your contribution to the ultimate source of distraction.";
		}

		else {
			return "Sorry, '$key' is already owned by " . $last->user . '.';
		}
	}

	else {
		$self->assignments->create(
			{
				user => $from,
				key => $key,
				value => $value,
			}
		);

		return "Thanks for your contribution to the ultimate source of distraction.";
	}
}


sub find {
	my ($self, $needle) = @_;

	my $result = $self->assignments->search(
		{
			-or => [
			key => { -ilike => '%' . $needle . '%' },
			value => { -ilike => '%' . $needle . '%' },
			],
		},
		{
			select => [ 'key', 'revision', ],
			order_by => 'key',
		},
	);

	my @result;

	for my $assignment ($result->slice(0, 14)) {
		push @result, $assignment->key . '[' . $assignment->revision . ']';
	}

	if(@result) {
		return join(', ', @result) . '.';
	}
	else {
		return 'No match.';
	}
}


sub read {
	my ($self, $key, $revision) = @_;

	my $assignment = $self->resolve($key, $revision);

	if(!$assignment) {
		my $result = $self->assignments->search( { key => { -ilike => $key . '%' } } );

		if($result->count != 1) {
			$result = $self->assignments->search( { key => { -ilike => '%' . $key . '%' } } );
		}

		if($result->count > 1) {
			my $uniq = { map { $_->key => $_ } $result->slice(0, 14) };

			if(keys(%{$uniq}) > 1) {
				my $list = join ', ', map { "'$_'" } keys %{$uniq};
				return 'Did you mean one of ' . $list . '?';
			}
			else {
				return $self->_format($self->resolve(keys(%{$uniq}), $revision));
			}
		}
		elsif($result->count == 0) {
			return 'No match.';
		}
		else {
			$assignment = $result->first;
		}
	}

	if($assignment) {
		return $self->_format($assignment);
	}

	return 'No match.';
}


sub resolve {
	my ($self, $key, $revision) = @_;

	my $result;

	if(defined($revision) and length($revision)) {
		$result = $self->assignments->search(
			{ key => { -ilike => $key }, revision => $revision, },
		);
	}
	else {
		$result = $self->assignments->search(
			{ key => { -ilike => $key }, },
			{ order_by => \'revision DESC', }
		);
	}

	return $result->first;
}


sub assignments {
	my ($self) = @_;

	return $self->nelson->schema->resultset('Assignment');
}


sub _format {
	my ($self, $assignment) = @_;

	my $key      = $assignment->key;
	my $value    = $assignment->value;
	my $time     = $assignment->when->strftime('on %F at %T');
	my $revision = $assignment->revision;
	my $user     = $assignment->user;

	return "'$key' is '$value' ($time, $user, r$revision).";
}


sub _tweet {
	my ($self, $text, $nick) = @_;

	return $self->{_nelson}->{loaded}->{twitter}->tweet('@' . $nick . ' ' . $text);
}


sub _aliases {
	return (
		'syn'         => 'syn23',
		'doomshammer' => 'doomshammer',
		'flummox'     => 'stefan',
		'flummi'      => 'stefan',
		'doomy'       => 'doomshammer',
		'syni'        => 'syn23',
		'jkramer'     => 'herrnelson',
		'cahne7Ki'    => 'herrnelson',
		'cahne6Ki'    => 'herrnelson',
		'unexist'     => 'unixist',
		'fucki'       => 'herrnelson',
		'fuckr'       => 'herrnelson',
	);
}


sub _resolve_nick {
	my ($self, $nick) = @_;

	my %aliases = $self->_aliases;

	return $aliases{lc $nick} || $nick;
}


sub _tweet_nelson {
	my ($self, $message, $nick) = @_;

	my $nelson = $self->_random_nelson;
	my $target = defined($nick) && length($nick) && $nick ? $self->_resolve_nick($nick) : $self->_random_user;

	my $tag = $self->{_nelson}->{loaded}->{twitter}->tweet('@' . $target . ' ' . $nelson);

	if($tag) {
		$message->reply('Haahaa! Successfully nelson\'ed @' . $target . ' via Twitter! ' . $tag);
	}
	else {
		$message->reply('Twitter is not configured.');
	}
}


sub _random_nelson {
	my ($self) = @_;

	my $nelsons = $self->assignments->search(
		{ key => { -ilike => '%nelson%' } },
	);

	my $rand = int(rand($nelsons->count));
	my ($nelson) = $nelsons->slice($rand, $rand + 1);

	return $nelson->value;
}


sub _random_user {
	my ($self) = @_;

	my %aliases = $self->_aliases;

	my %targets = map { $_ => 1 } values %aliases;
	my @targets = keys %targets;

	return $targets[int rand @targets];
}


1
