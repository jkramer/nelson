
package Nelson::Plugin::IMDB;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use IMDB::Film;


sub namespace { 'imdb' }


sub priority { 999 }


sub message {
	my ( $self, $message ) = @_;

	if( $message->text =~ m/^!imdb\s+(.+)$/i ) 
	{

		my $givenTitle = $1;

		my $imdb = IMDB::Film->new( crit => $givenTitle );
		if( $imdb->status )
		{

			my $title = $imdb->title();
			my $code  = $imdb->code();
			my $year  = $imdb->year();
			my( $rating, $vnum, $avards ) = $imdb->rating();

			$message->reply( 
				$title . ' (' . $year . ') - IMDB Rating: ' . $rating . '/10 (' . $vnum . ' votes)'
				. ' // IMDB: http://www.imdb.com/title/tt' . $code . '/'
			);

		} else {

			$message->reply( 'Haahaa! IDMB said: ' . $imdb->error() . '!' );

		}

	}
	elsif( $message->text =~ m#^http://www\.imdb\.com/title/tt(\d+)/?$#i )
	{
		
		my $code = $1;

		my $imdb = IMDB::Film->new( crit => $code );
		if( $imdb->status )
		{

			my $title = $imdb->title();
			my $year  = $imdb->year();
			my( $rating, $vnum, $avards ) = $imdb->rating();

			$message->reply( 
				$title . ' (' . $year . ') - IMDB Rating: ' . $rating . '/10 (' . $vnum . ' votes)'
			);

		} else {

			$message->reply( 'Haahaa! IDMB said: ' . $imdb->error() . '!' );

		}

	}

	return 1;
}


1
