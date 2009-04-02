
=head1 NAME

Nelson::IRC

=head1 SYNOPSIS

	my $irc = new Nelson::IRC;

	$irc->connect('irc.freenode.net');

=head1 DESCRIPTION

Yet another lightweight implementation of the IRC protocol...

=head1 METHODS

=over 4

=cut

package Nelson::IRC;

use strict;
use warnings;

use IO::Socket::INET;
use IO::Socket::SSL;

our $AUTOLOAD;


# [sub] new -> * 
sub new {
	my ($class, %option) = @_;

	return bless {
		%option,

		name => undef,

		username => undef,
		password => undef,

		host => undef,
		port => $option{ssl} ? 6697 : 6667,

		callback => undef,
	}, $class;
}


# [sub] connect -> host [, port] 
sub connect {
	my ($self, $host, $port, $bind) = @_;

	$self->host($host) if $host;
	$self->port($port) if $port;

	if($self->{ssl}) {
		$self->{socket} = new IO::Socket::SSL(
			PeerHost => $self->host,
			PeerPort => $self->port,
			$bind ? ( LocalHost => $bind ) : (),
		);
	}
	else {
		$self->{socket} = new IO::Socket::INET(
			PeerHost => $self->host,
			PeerPort => $self->port,
			$bind ? ( LocalHost => $bind ) : (),
		);
	}

	return unless $self->{socket};

	$self->send('PASS', $self->{password}) if($self->{password});
	$self->send('NICK', $self->name);

	$self->send(
		'USER',
		$self->name,
		'tolmoon',
		$self->host,
		':Ronnie Reagan'
	);

	return !0;
}


# [sub] send -> command [, params] 
sub send {
	my $self = shift;

	my $socket = $self->{socket};
	my $prefix = $self->prefix;

	$socket->print($prefix, "@_", "\r\n");
}


# [sub] prefix -> * 
sub prefix {
	my ($self) = @_;

	return $self->name ? ':' . $self->name . ' ' : '';
}


# [sub] quit -> [message] 
sub quit {
	my ($self, $message) = @_;
	$self->send($message ? ('QUIT', $message) : 'QUIT');
	
	my $socket = $self->{socket};
	$socket->close;
}


# [sub] loop -> * 
sub loop {
	my ($self) = @_;

	my $socket = $self->{socket};

	while(my $message = readline($socket)) {
		my ($prefix, $command, @p) = ($self->parse($message));

		chomp $message;

		$command = uc $command;

		if($command !~ /\D/ and $command >= 400 and $command < 600) {
			print "ERROR: $command @p\n";
		}

		if($command eq 'PING') {
			$self->send('PONG', $self->host);
		}

		my $callback = $self->{callback};

		if($callback) {
			$callback = $callback->{$command};
			&{$callback}($self, $prefix, $command, @p) if($callback);
		}
	}
}


# [sub] parse -> message 
sub parse {
	my ($self, $message) = @_;
	my ($prefix, $text);

	$message =~ s/\r?\n$//;

	# Strip off prefix.
	if($message =~ /^:(\S+)/) {
		$prefix = $1;
		$message =~ s/^\S+ //;
	}

	# Get text parameter if existing.
	if($message =~ /\s+:(.*)$/) {
		$text = $1;
		$message =~ s/\s+:(.*)$//;
	}

	return ($prefix, (split /\s+/, $message), $text);
}


# [sub] join -> channel [, key] 
sub join {
	my ($self, $channel, $key) = @_;

	$self->send('JOIN', $key ? ($channel, $key) : $channel);
}


# [sub] message -> target, text 
sub message {
	my ($self, $target, $text) = @_;

	$self->send('PRIVMSG', $target, ":$text");
}


# [sub] callback -> event, code 
sub callback {
	my ($self, $event, $code) = @_;
	$self->{callback}->{$event} = $code;
}


# [sub] AUTOLOAD 
sub AUTOLOAD {
	my ($self, $value) = @_;

	my $field = (split /::/, $AUTOLOAD)[-1];

	die "Unknown method/attribute $field.\n" unless exists $self->{$field};

	$self->{$field} = $value if($#_ > 0);

	return $self->{$field};
}

sub DESTROY {}

!0;
