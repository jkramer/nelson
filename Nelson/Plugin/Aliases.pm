

package Nelson::Plugin::Aliases;

use strict;
use warnings;

use base qw( Nelson::Plugin );


sub namespace { 'aliases' }


sub priority { 1001 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	$self->{aliases} = { %cfg };
	$self->{_nelson} = $nelson;
}


sub aliases {
	my ($self) = @_;

	return %{$self->{aliases}};
}


sub resolve_nick {
	my ($self, $nick) = @_;

	my %aliases = $self->aliases;

	return $aliases{lc $nick} || $nick;
}


sub random_user {
	my ($self) = @_;

	my %aliases = $self->aliases;

	my %targets = map { $_ => 1 } values %aliases;
	my @targets = keys %targets;

	return $targets[int rand @targets];
}


1
