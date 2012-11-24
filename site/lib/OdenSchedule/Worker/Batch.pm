package OdenSchedule::Worker::Batch;

use strict;
use warnings;
use utf8;

sub new {
	my ($class, $app, $db) = @_;
	my $self = bless({}, $class);
	
	$self->{app}= $$app;
	$self->{db}	= $$db;
	
	
	$self->{app}->log->debug("-----Worker::Batch-----");
	
	return $self;
}

sub findBatch {
	my $self = shift;
	
}

1;