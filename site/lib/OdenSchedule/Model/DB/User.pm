package OdenSchedule::Model::DB::User;
# Database Module - User Collection

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

# addUser($userHash)	-	add new user (return: _ID)
sub addUser {
	my ($self, $userHash) = @_;
	return $self->{dbc}->insert($userHash);
}

# updateUser($userHash)	-	update user (return: 1)
sub updateUser {
	my ($self, $userHash) = @_;
	return $self->{dbc}->update({$userHash->_id}, $userHash);
}

# upsertUser($userHash)	-	add or update user (return: 1)
sub upsertUser {
	my ($self, $userHash) = @_;
	return $self->{dbc}->update({$userHash->_id}, $userHash, {"upsert" => 1});
}

# deleteUser($userId)	-	delete user (return: 1)
sub deleteUser {
	my ($self, $id) = @_;
	return $self->{dbc}->remove({ _id => $id});
}

1;