package OdenSchedule::Model::User;
# User Object module

use strict;
use warnings;

use OdenSchedule::Model::DB::User;

sub new {
	my ($class, $userId) = @_;
	my $self = bless({}, $class);
	
	if(defined($userId)){
		OdenSchedule::Model::DB::User->new();
		
	}else{
		OdenSchedule::Model::DB::User->new();
	}
	 
	return $self;
}

1;