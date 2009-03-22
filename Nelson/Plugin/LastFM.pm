
package Nelson::Plugin::LastFM;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use LWP::UserAgent;


sub namespace { 'lastfm' }


sub priority { 100 }


sub message {
	my ($self, $message) = @_;

	if($message->text =~ /^!scrob\s+(.+?)\s*$/) {
		my $login = $1;
		my $scrobble = $self->scrobbles->find($message->from);

		if($scrobble) {
			$scrobble->login($login);
			$scrobble->update;
		}
		else {
			$self->scrobbles->create(
				{ user => $message->from, login => $login },
			);
		}

		$message->reply('Saved, probably successful.');
	}

	elsif($message->text =~ /^!np\s*$/) {
		my $scrobble = $self->scrobbles->find($message->from);

		if($scrobble) {
			if($scrobble->time and $scrobble->time > (time - 30)) {
				$message->send($message->from . " just played " . $scrobble->track . '.');
			}

			else {
				my $agent = new LWP::UserAgent;

				my $base = 'ws.audioscrobbler.com';
				my $encoded = $scrobble->login;

				$encoded =~ s/(\W)/sprintf('%%%02X', ord($1))/eg;

				my $response = $agent->get(
					"http://$base/1.0/user/$encoded/recenttracks.txt"
				);

				if($response->is_success) {
					my $body = $response->content;

					if($body) {
						my $last = (split /\r?\n/, $body)[0];
						$last =~ s/^\d+,//;

						my ($artist, $track) = split /\x20\xE2\x80\x93\x20/, $last;

						$track = qq|"$track" by $artist|;

						$scrobble->time(time);
						$scrobble->track($track);

						$scrobble->update;

						$message->send($message->from . " just played $track.");
					}
				}
			}

		}

		else {
			$message->reply("You don't have a Last.FM account configured.");
		}
	}

	return 1;
}


sub scrobbles {
	my ($self) = @_;

	return $self->nelson->schema->resultset('Scrobble');
}


1
