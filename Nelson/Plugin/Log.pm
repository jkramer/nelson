
package Nelson::Plugin::Log;

use strict;
use warnings;

use base qw( Nelson::Plugin );

use IO::File;


sub namespace { 'log' }


sub priority { 0 }


sub initialize {
	my ($self, $nelson, %cfg) = @_;

	if($cfg{path}) {
		$self->{log_file} = new IO::File($cfg{path}, '>>') or die "Can't create log file $cfg{path}.\n";
		$self->{log_file}->autoflush(1);
	}
	else {
		warn "Log plugin loaded, but no log path configured.\n";
	}
}


sub message {
	my ($self, $message) = @_;

	if($self->{log_file}) {
		my $from = $message->from;
		my $text = $message->text;
		my $time = localtime;

		$self->{log_file}->write("$time <$from> $text\n");
	}

	return 1;
}


1
