
package Nelson::Schedule;

use strict;
use warnings;


use base qw( Class::Singleton );


sub new {
	my ($class) = @_;

	return bless {
		jobs => [],
	}, $class;
}


sub fork_loop {
	my ($self, $nelson) = @_;

	my $now = time;
	$_->last_run($now) for(@{$self->{jobs}});

	my $pid = fork;

	if(defined $pid) {
		if($pid == 0) {
			while(1) {
				$0 = "nelson-ng [job schedule]";

				my $next_job = $self->get_next_job;

				last unless $next_job;

				while($next_job->next > time) {
					sleep($next_job->next - time);
				}

				$0 = "nelson-ng [job: " . $next_job->name . "]";
				$next_job->run($nelson);
			}

			exit;
		}

		else {
			$self->{loop_pid} = $pid;
		}
	}
	else {
		die "Failed to fork. $!.\n";
	}
}


sub get_next_job {
	my ($self) = @_;

	my ($next_job) = sort { $a->next <=> $b->next } @{$self->{jobs}};

	return $next_job;
}


sub register {
	my ($self, $job) = @_;

	push @{$self->{jobs}}, $job;
}


sub terminate {
	my ($self) = @_;

	if($self->{loop_pid}) {
		kill $self->{loop_pid};
		wait;
	}
}


1
