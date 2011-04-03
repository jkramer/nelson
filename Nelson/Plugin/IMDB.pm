
package Nelson::Plugin::IMDB;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use IMDB::Film;
use WWW::Mechanize;


sub namespace { 'imdb' }


sub priority { 999 }


sub message {
	my ( $self, $message ) = @_;

	$self->{_mechanize} ||= new WWW::Mechanize ( autocheck => 0, timeout => 2 );

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
	elsif( $message->text =~ m/^!randimdb$/i ) 
	{

		my $minrate = 6.8;
		my $url = 'http://www.imdb.com/search/title?sort=moviemeter,asc&start=' . int( rand( 10000 ) + 1 ) . '&title_type=feature&user_rating=' . $minrate . ',10&view=simple';

		$self->mechanize->agent_alias('Windows IE 6');
		$self->mechanize->get($url);

		my @links = $self->mechanize->find_all_links( url_regex => qr|/title/tt\d+| );
		
		my $imdb = IMDB::Film->new( crit => $1 ) if ( $links[ int(rand(100) + 1) ]->[0] =~ m#^/title/tt(\d+)/?$# );
	
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

sub mechanize {
    my ($self) = @_;

    $self->{_mechanize} ||= new WWW::Mechanize;

    return $self->{_mechanize};
}

1
