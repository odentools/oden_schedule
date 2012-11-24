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
	
	my $crawler = OdenSchedule::Model::ScheduleCrawler->new(
		'db' => \($self->app->db),
		'own_user' => \($self->ownUser),
		'logger' => \($self->app->log),
		'config' => \($self->config),
	);
	
	$crawler->upsertCrawlToDatabase();
	
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
