package OdenSchedule::Model::CalendarOrganizer;
##################################################
# Googleカレンダー操作モデル
##################################################

use strict;
use warnings;
use utf8;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	$self->{db}	= ${$hash{db}} || die ('Not specified db instance.');# データベースインスタンス
	$self->{api_key} = $hash{api_key} || die ('Not specified api_key.');
	$self->{consumer_key} = $hash{consumer_key} || die ('Not specified consumer_key.');
	$self->{consumer_secret} = $hash{consumer_secret} || die ('Not specified consumer_secret.');
	$self->{oauth_access_token} = $hash{oauth_access_token} || die ('Not specified oauth_accessToken.');
	$self->{oauth_refresh_token} = $hash{oauth_refresh_token} || die ('Not specified oauth_refresh_token.');
	
	$self->{gcal} = undef;
	
	return $self;
}

sub initGcal_{
	my $self = shift;
	if(!defined($self->{gcal})){
		$self->{gcal} = Net::Google::CalendarLite->new(
			'api_key' => $self->{api_key},
			'consumer_key'	=> $self->{consumer_key},
			'consumer_secret'	=>	$self->{consumer_secret},
			'oauth_access_token'	=>	$self->{oauth_access_token},
			'oauth_refresh_token'=>	$self->{oauth_refresh_token}
		);
	}
}

sub getCalendarList {
	my $self = shift;
	$self->initGcal_();
	return $self->{gcal}->getCalendarList();
}

sub eventFindOrInsert {
	my ($self, %param) = @_;
	$self->initGcal_();
	$self->insertEvent(%param);
}

1;