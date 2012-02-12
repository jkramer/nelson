
package Nelson::Plugin::Hangman;

use strict;
use warnings;

our @ISA = qw( Nelson::Plugin );

use List::Util qw ( sum );

use constant WORDLIST_PATH => '/tmp/nelson_hangman_wordlist.txt';

sub namespace { 'hangman' }


sub priority { 1001 }


sub new {
	my ($class) = @_;

	return bless {
		wordlist     => {},
		current_game => undef,
	}, $class;
}


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	@{$self}{keys %cfg} = values %cfg;

	$self->{_nelson} = $nelson;

	$self->{wordlist} = $self->load_wordlist;
}


sub message {
	my ($self, $message) = @_;

	# Collect words.
	if($message->text !~ /^!/) {
		my $line = lc $message->text;
		my $changes = 0;

		for my $word ($line =~ /(?=(?:^|\s)([a-z]{4,})(?:\s|$))/ig) {
			$self->{wordlist}->{$word}++;
			++$changes;
		}

		$self->store_wordlist if($changes);
	}

	if($message->text =~ /^!hangman/) {
		my $word = $self->random_word;

		$self->{current_game} = {
			word    => $word,
			guesses => 8,
			letters => {},
		};

		$message->send($self->game_status);
	}

	elsif($self->{current_game} && $message->text =~ /^([a-z]+)(\?{1,2})$/i) {
		my $guess = lc $1;
		my $game = $self->{current_game};

		if(length($guess) == 1 || $2 eq '??') {
			for(split //, $guess) {
				if(!$game->{letters}->{$_}++) {
					--$game->{guesses} if($game->{word} !~ /\Q$_\E/);
				}
			}

			$message->send($self->game_status);
		}
		else {
			if($game->{word} eq $guess) {
				++$game->{letters}->{$_} for(split //, $guess);
			}
			else {
				$message->send('Fail!');
				--$game->{guesses};
			}

			$message->send($self->game_status);
		}
	}

	elsif($message->text =~ /^!blacklist\s+([a-z]+)\s*$/) {
		$self->{wordlist}->{$1} = -1;
		$self->store_wordlist;
	}

	return 1;
}


sub game_status {
	my ($self) = @_;

	my $game = $self->{current_game};

	if($game) {
		my $word = $game->{word};

		for my $letter (split //, $word) {
			$word =~ s/\Q$letter\E/_/g unless($game->{letters}->{$letter});
		}

		my $won = $word eq $game->{word};

		if($won) {
			delete $self->{current_game};
			return "You win! \\o/ ($game->{word})";
		}
		elsif($game->{guesses} == 0) {
			delete $self->{current_game};
			return "You lose! The word was '$game->{word}'.";
		}
		else {
			my $letters = join('', sort keys %{$game->{letters}});
			my $length = length($word);
			my @blurr = (-2, -1, -1, 0, 0, 0, 1, 1, 2);
			$length += $blurr[int rand scalar @blurr];
			return "$word (about $length letters); $game->{guesses} left; [$letters]";
		}
	}

	else {
		return "We're not playing right now.";
	}
}


sub random_word {
	my ($self) = @_;

	my @words = $self->good_words;

	if(@words) {
		return $words[int rand scalar @words];
	}
	else {
		return 'hangman';
	}
}


sub good_words {
	my ($self) = @_;

	my %words = %{$self->{wordlist}};
	my $total = 0;

	for my $word (keys %words) {
		if($words{$word} == -1) {
			print "$word is blacklisted\n";
			next;
		}

		my %letters = map { $_ => 1 } split //, $word;

		if(
			length($word) / scalar(keys %letters) > 3.0
			||
			keys(%letters) < 3 || $word =~ /([aeiou])\1{2}/
		) {
			delete $words{$word};
		}
		else {
			$total += $words{$word};
		}
	}

	my $max = $total / 10.0;
	my @good_words;
	my $score = 0;

	for my $word (sort { $words{$a} <=> $words{$b} || length($b) <=> length($a) } keys(%words)) {
		$score += $words{$word};
		push @good_words, $word;
		last if($score >= $max);
	}

	return @good_words;
}


sub load_wordlist {
	if(open FH, WORDLIST_PATH) {
		my $wordlist = {};

		while(my $line = <FH>) {
			chomp $line;
			my ($word, $count) = split(':', $line);
			$wordlist->{$word} = $count;
		}

		close FH;

		return $wordlist;
	}
	else {
		warn "Can't open wordlist. $!.";
		return {};
	}
}


sub store_wordlist {
	my ($self) = @_;

	if(open FH, '>', WORDLIST_PATH) {
		while(my ($word, $count) = each %{$self->{wordlist}}) {
			print FH "$word:$count\n";
		}
		close FH;
	}
	else {
		warn "Can't open wordlist. $!.";
	}
}


1
