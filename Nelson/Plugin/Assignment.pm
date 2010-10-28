
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

		if( (int(rand(40)) % 40) == 0 ) {
			my $nelsons = $self->assignments->search(
				{ key => { -ilike => '%nelson%' } },
			);

			my $rand = int(rand($nelsons->count)) + 1;
			my ($nelson) = $nelsons->slice($rand, $rand + 1);

			$message->{channel} = '#dokuleser';
			$message->send('Random Nelson: ' . $nelson->value);
		}
	}

	return 1;
}


sub message {
	my ($self, $message) = @_;

	my $text = $message->text;
	my $from = $message->from;

	my @hashtag = qw( #loveparade #android #ipad #itampon #apple #h1n1 #bundestag #cdu #jesustweeters #fdp #spd #iphone #twitter #merkel #westerwelle #berlin #google );
	my $rand = int(rand($#hashtag));
	my $randhash = $hashtag[$rand];

	my %aliases = (
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

	elsif($text =~ /^!nelson\s+(\w+)*\s*$/) {
		my $nelsons = $self->assignments->search(
			{ key => { -ilike => '%nelson%' } },
		);
		my $sendto = $1;

		my $rand = int(rand($nelsons->count)) + 1;
		my ($nelson) = $nelsons->slice($rand, $rand + 1);

		if(defined($sendto) and length($sendto)) {
			$message->send($sendto . ': ' . $nelson->value);
		} else {
			$message->send($nelson->value);
		}
	}

	elsif($text =~ /^!selfnelson\s*$/) {
		my $nelsons = $self->assignments->search(
			{ key => { -ilike => '%nelson%' } },
		);

		my $rand = int(rand($nelsons->count)) + 1;
		my ($nelson) = $nelsons->slice($rand, $rand + 1);

		$message->reply($nelson->value);
	}

	elsif($text =~ /^!ftw\s*(.*)$/) {
		my $sendto = $1;
		$message->send($sendto . ' ftw! \o/');
	}

	elsif($text =~ /^!twitson\s+(.+?)\s*$/) {
		my $rsendto = $1;

		my $nelsons = $self->assignments->search(
			{ key => { -ilike => '%nelson%' } },
		);
		my $rand = int(rand($nelsons->count)) + 1;
		my ($nelson) = $nelsons->slice($rand, $rand + 1);

		if($self->{_nelson}->{loaded}->{twitter}->{twitter}) {
			my ($tosend, $sendto);
			if(defined($aliases{lc($rsendto)})) {
				$sendto = $aliases{ lc( $rsendto ) };
			}
			else {
				$sendto = $rsendto;
			}
			my $update = $nelson->value;
			my $len = length( $randhash );
			my $mes = length( $update );
			my $tol = length( '@' . $sendto . ' ' );
			my $tot = ( $tol + $len + $mes );
			if( $tot > 140 )
			{
				$tosend = substr( '@' . $sendto . ' ' . $update, 0, ( 140 - $len - $tol - 6 ) ) . '[...]' . ' ' . $randhash;

			} else {

				$tosend = '@' . $sendto . ' ' . $update . ' ' . $randhash;

			}
			$self->{_nelson}->{loaded}->{twitter}->{twitter}->update( $tosend );
			$message->reply('Haahaa! Successfully nelson\'ed @' . $sendto . ' via Twitter! ' . $randhash);
		}
		else {
			$message->reply('Twitter is not configured.');
		}
	}

	elsif($text =~ /^!randson\s*$/) {
		my $sendto = $aliases{[keys %aliases]->[int rand keys %aliases]};

		my $nelsons = $self->assignments->search(
			{ key => { -ilike => '%nelson%' } },
		);
		my $rand = int(rand($nelsons->count)) + 1;
		my ($nelson) = $nelsons->slice($rand, $rand + 1);

		if($self->{_nelson}->{loaded}->{twitter}->{twitter}) {
			my ( $tosend );
			my $update = $nelson->value;
			my $len = length( $randhash );
			my $mes = length( $update );
			my $tol = length( '@' . $sendto . ' ' );
			my $tot = ( $tol + $len + $mes );
			if( $tot > 140 )
			{
				$tosend = substr( '@' . $sendto . ' ' . $update, 0, ( 140 - $len - $tol - 6 ) ) . '[...]' . ' ' . $randhash;

			} else {

				$tosend = '@' . $sendto . ' ' . $update . ' ' . $randhash;

			}
			$self->{_nelson}->{loaded}->{twitter}->{twitter}->update( $tosend );
			$message->reply('Haahaa! Successfully nelson\'ed @' . $sendto . ' via Twitter! ' . $randhash);
		}
		else {
			$message->reply('Twitter is not configured.');
		}
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

	if($message->{command} eq 'PING') {
		my $rand = int(rand($self->assignments->count)) + 1;
		my ($assignment) = $self->assignments->slice($rand, $rand + 1);

		$message->send($self->_format($assignment));
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


1
