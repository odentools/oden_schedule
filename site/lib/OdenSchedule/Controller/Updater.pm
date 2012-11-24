package OdenSchedule::Controller::Updater;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

use Net::OECUMailOAuth;
use OdenSchedule::Model::ScheduleCrawler;
use OdenSchedule::Model::CalendarOrganizer;
use Net::Google::CalendarLite;
use Encode;

# 休講・補講情報の取得
sub oecu_schedule {
	my $self = shift;

	if(!defined($self->flash("dialog")) || $self->flash("dialog") ne "false"){
		$self->flash("dialog", "false");
		$self->render();
		return 1;
	}
	
	my $user_id = $self->ownUserId();
	
	# 休講・補講情報
	my $crawler = OdenSchedule::Model::ScheduleCrawler->new('username' =>'ht11a018', 'oauth_accessToken' =>$self->ownUser->{google_token});
	
	my @schedules;
	eval{
		@schedules = $crawler->crawl();
	}; 
	$self->app->log->error("Crawler:".$crawler->{logs});
	if($@){
		# トークンの有効期限切れならば...
		$self->app->plugin('OdenSchedule::Helper::Login');
		
		my $user = $self->ownUser();
		my $oauth = $self->oauth_client_google_refresh;
		eval { 
			my $access_token = $oauth->get_access_token($user->{google_reftoken}, grant_type => "refresh_token");
			$user->google_token($access_token->{access_token});
			$user->update();
		};
		if($@){
			# リフレッシュトークンも無効ならば...
			$self->redirect_to('/session/login');
			return;	
		}
	}
	
	# Insert events to Database 
	foreach my $item(@schedules){
		my $hash_str;
		foreach(keys %$item){
			$hash_str .= $_."_".$item->{$_};
		}
		my $hash_id = Digest::SHA1::sha1_base64(Encode::encode_utf8($hash_str));
		my $db_item = $self->getScheduleObj('hash_id' => $hash_id);
		if(! $db_item->{isFound}){ # not found on DB
			# Set other values
			$item->{user_id} = $user_id;
			$item->{hash_id} = $hash_id;
			
			# Insert to DB
			$db_item->set(%$item);
		}
	}
	$self->redirect_to('/top');

}

# カレンダーの登録＆更新
sub calendar {
	my $self = shift;	
	if(!defined($self->flash("dialog")) || $self->flash("dialog") ne "false"){
		$self->flash("dialog", "false");
		$self->render();
		return 1;
	}
	
	my $calorg = OdenSchedule::Model::CalendarOrganizer->new(
		'db' => \($self->app->db),
		'own_user' => \($self->ownUser),
		'logger' => \($self->app->log),
		'config' => \($self->config),
	);
	$calorg->upsertDatabaseToCalendar();
	
	$self->redirect_to('/top');
}

1;
