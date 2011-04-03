
package Nelson::Schedule::Job;

use strict;
use warnings;


use base qw( Class::Accessor::Fast );

__PACKAGE__->mk_accessors(qw( name interval code last_run ));


sub new {
	my ($class, $name, $interval, $code) = @_;

	my $self = bless {
		name => $name,
		interval => $interval,
		code => $code,
		last_run => 0,
	}, $class;

	return $self;
}


sub run {
	my ($self, $nelson) = @_;

	&{$self->code}($nelson);
	$self->last_run(time);
}


sub next {
	my ($self) = @_;

	return $self->last_run + $self->interval;
}


1
