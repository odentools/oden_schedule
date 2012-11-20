package OdenSchedule::Model::DB::Schedule;
# Database Module - Schedule Collection

use strict;
use warnings;
use utf8;

sub new {
	my ($class, $dbRef) = @_;
	my $self = bless({}, $class);
	$self->{db} = $$dbRef;
	$self->{dbc} = $self->{db}->things;
	return $self;
}

# addSchedule($scheduleHash)	-	add new schedule (return: _ID)
sub addSchedule {
	my ($self, $scheduleHash) = @_;
	return $self->{dbc}->insert($scheduleHash);
}

# updateSchedule($scheduleHash)	-	update schedule (return: 1)
sub updateSchedule {
	my ($self, $scheduleHash) = @_;
	return $self->{dbc}->update({$scheduleHash->_id}, $scheduleHash);
}

# upsertSchedule($scheduleHash)	-	add or update schedule (return: 1)
sub upsertSchedule {
	my ($self, $scheduleHash) = @_;
	return $self->{dbc}->update({$scheduleHash->_id}, $scheduleHash, {"upsert" => 1});
}

# deleteSchedule($scheduleId)	-	delete schedule (return: 1)
sub deleteSchedule {
	my ($self, $id) = @_;
	return $self->{dbc}->remove({ _id => $id});
}

1;