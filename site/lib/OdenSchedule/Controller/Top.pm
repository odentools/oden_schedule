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
	
	# 休講・補講情報
	my $crawler = OdenSchedule::Model::ScheduleCrawler->new('username' =>'ht11a018', 'oauth_accessToken' =>$self->ownUser->{google_token});
	
	my @schedules;
	eval{
		@schedules = $crawler->crawl();
	}; 
	if($@){
		# トークンの有効期限切れならば...
		$self->app->plugin('OdenSchedule::Helper::Login');
		
		my $user = $self->ownUser();
		my $oauth = $self->oauth_client_google_refresh;
		my $access_token;
		eval { 
			$access_token = $oauth->get_access_token($user->{google_reftoken});
			$user->google_token($access_token->{access_token});
			$user->google_reftoken($access_token->{refresh_token});
		};
		if($@){
			# リフレッシュトークンも無効ならば...
			$self->redirect_to('/session/login');
			return;	
		}
		$self->redirect_to('/top');
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
	#eval{
		@calendars = $calorg->getCalendarList()->[0];
	#};
	$self->stash('calendars', \@calendars);
	
	$self->stash( 'isUser_google', 1 );
	$self->render();
}

1;
