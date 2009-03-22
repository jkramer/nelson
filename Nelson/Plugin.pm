
package Nelson::Plugin;

use strict;
use warnings;

use Carp;


sub new {
	my ($class) = @_;

	return bless {
		# ...
	}, $class;
}


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	@{$self}{keys %cfg} = values %cfg;

	$self->{_nelson} = $nelson;
}


sub nelson {
	my ($self) = @_;

	return $self->{_nelson};
}


sub namespace {
	croak 'Abstract method namespace not overridden';
}


sub priority { 1000 }


1
