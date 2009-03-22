
package Nelson::Plugin::Assignment;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'assign' }


sub priority { 5 }


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

		$revision = undef unless length($revision);

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

	elsif($text =~ /^!nelson\s*$/) {
		my $nelsons = $self->assignments->search(
			{ key => { -ilike => '%nelson%' } },
		);

		my $rand = int(rand($nelsons->count)) + 1;
		my ($nelson) = $nelsons->slice($rand, $rand + 1);

		$message->send($nelson->value);
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

			return "Thanks for your contribution to the ultimate source of all knowledge.";
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

		return "Thanks for your contribution to the ultimate source of all knowledge.";
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

	return join(', ', @result) . '.';
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
			my $uniq = { map { $_->key => $_ } $result->get_column('key') };
			my $list = join ', ', map { "'$_'" } values %{$uniq};

			return 'Did you mean on of ' . $list . '?';
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
