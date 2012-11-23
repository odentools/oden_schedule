package OdenSchedule::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

use Net::OECUMailOAuth;
use OdenSchedule::Model::ScheduleCrawler;
use OdenSchedule::Model::CalendarOrganizer;
use Net::Google::CalendarLite;

sub top_guest {
	my $self = shift;
	if ( $self->ownUserId() ne "" ) {
		$self->redirect_to("/top");
		return;
	}
	$self->render();
}

sub top_user {
	my $self = shift;
	
	if(defined($self->param('set_calendar_id'))){
		$self->ownUser->calendar_id_gcal($self->param('set_calendar_id'));
		$self->ownUser->update();
		$self->render_json({status => 1, calendar_id => $self->param('set_calendar_id')});
		return;
	}
	
	# 休講・補講情報
	my @schedules;
	my $iter = $self->db->get(schedule => {where => ['user_id' => $self->ownUser->{id}]});
	while(my $item = $iter->next){
		push(@schedules, $item->{column_values});
	}
	$self->stash('schedules', \@schedules);
	
	# カレンダーリスト
	my $calorg = OdenSchedule::Model::CalendarOrganizer->new(
		'username' =>'ht11a018',
		'oauth_access_token' =>$self->ownUser->{google_token}, 
		'oauth_refresh_token' =>$self->ownUser->{google_reftoken}, 
		'api_key' => $self->config()->{social_google_apikey},
		'consumer_key' => $self->config()->{social_google_key},
		'consumer_secret' => $self->config()->{social_google_secret},
	);
	my @calendars;
	$self->stash( 'message_error', "");
	eval{
		@calendars = $calorg->getCalendarList();
	}; $self->stash('message_error', $@) if($@);
	
	$self->stash('calendars', @calendars);
	
	$self->stash( 'isUser_google', 1 );
	$self->render();
}

1;
