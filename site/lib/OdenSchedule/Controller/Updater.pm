package OdenSchedule::Controller::Updater;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

use Net::OECUMailOAuth;
use OdenSchedule::Model::ScheduleCrawler;
use OdenSchedule::Model::CalendarOrganizer;
use Net::Google::CalendarLite;

sub oecu_schedule {
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
	}
	$self->redirect_to('/top');
}

1;
