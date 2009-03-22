
package Nelson::Plugin::Score;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'score' }


sub priority { 100 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!(--|\+\+)\s*(.+?)\s*$/) {
		my ($mode, $key) = ($1, $2);

		my $score = $self->scores->find($key);
		my $modification = $mode eq '++' ? 1 : -1;

		if($score) {
			$score->score($score->score + $modification);
		}
		else {
			$score = $self->scores->create(
				{ key => $key, score => $modification }
			);
		}

		$message->reply('Score of ' . $score->key . ' is now ' . $score->score . '.');
	}

	elsif($message->text =~ /^!good\s*$/) {
		my $good = $self->scores->search(
			undef,
			{
				order_by => \'score DESC',
			}
		);

		my @good;

		for my $score ($good->slice(0, 9)) {
			push @good, [ $score->key, $score->score ];
		}

		$message->reply(join('; ', map { $_->[0] . ': ' . $_->[1] } @good) . '.');
	}

	elsif($message->text =~ /^!bad\s*$/) {
		my $bad = $self->scores->search(
			undef,
			{
				order_by => \'score ASC',
			}
		);

		my @bad;

		for my $score ($bad->slice(0, 9)) {
			push @bad, [ $score->key, $score->score ];
		}

		$message->reply(join('; ', map { $_->[0] . ': ' . $_->[1] } @bad) . '.');
	}

	return 1;
}


sub scores {
	my ($self) = @_;

	return $self->nelson->schema->resultset('Score');
}


1
