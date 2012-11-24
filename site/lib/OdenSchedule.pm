package OdenSchedule;
use Mojo::Base 'Mojolicious';
use Mojo::IOLoop;

use MongoDB;
use Data::Model;
use Data::Model::Driver::MongoDB;

use Net::OECUMail;
use Net::OAuth2;
use Net::OAuth2::Client;
use Digest::SHA1;
use Time::Piece ();

use OdenSchedule::DBSchema;
use OdenSchedule::Model::User;
use OdenSchedule::Model::Schedule;
use OdenSchedule::Worker::Batch;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Documentation browser under "/perldoc"
	$self->plugin('PODRenderer');
	
	# ルータの初期化
	my $r = $self->routes;
	
	# ネームスペースのセット
	$r->namespace('OdenSchedule::Controller');
	
	# 設定のロード
	my $conf = $self->plugin('Config',{file => 'config/config.conf'});
	
	# Cookieの暗号化キーをセット
	$self->secret('odenschedule'.$conf->{secret});
	
	# データベースの準備
	my $mongoDB = Data::Model::Driver::MongoDB->new( 
		host => 'localhost',
		port => 27017,
		db => 'odenschedule',
	);
	my $schema = OdenSchedule::DBSchema->new;
	$schema->set_base_driver($mongoDB);
	
	# データベースヘルパーのセット
	$self->attr(db => sub { return $schema; });
	$self->helper('db' => sub { shift->app->db });
	
	# データベースモデルのセット
	$self->helper('getUserObj' => sub {
		my ($self, %hash) = @_;
		return OdenSchedule::Model::User->new( \($self->app->db), \($self->app->log), \%hash );
	});
	$self->helper('getScheduleObj' => sub {
		my ($self, %hash) = @_;
		return OdenSchedule::Model::Schedule->new( \($self->app->db), \($self->app->log), \%hash );
	});
	
	# バッチ処理用タイマー
	Mojo::IOLoop->recurring(120 => sub {	return OdenSchedule::Worker::Batch->new(\($self->app),\($self->app->db)); });
	Mojo::IOLoop->singleton->reactor->on(error => sub { my ($reactor, $err) = @_; $self->app->log->error($err); });
	
	# ユーザ情報ヘルパーのセット
	$self->helper('ownUserId' => sub { return undef });
	$self->helper('ownUser' => sub { return undef });
	$self->stash(logined => 0);
	
	# ログヘルパーのセット
	$self->helper('log' => sub { shift->app-> log });
	
	# 認証用のルート
	$r->route('/session/oauth_google_redirect')->to('session#oauth_google_redirect',);
	$r->route('/session/oauth_google_callback')->to('session#oauth_google_callback',);
	
	# 前処理を行うブリッジ (認証セッションチェックなど)
	$r = $r->bridge->to('bridge#login_check');
	
	# 通常のルート
	$r->route('')->to('top#top_guest',);
	$r->route('/top')->to('top#top_user',);
	$r->route('/updater/oecu_schedule')->to('updater#oecu_schedule',);
	$r->route('/updater/calendar')->to('updater#calendar',);
	$r->route('/docs/about')->to('docs#about',);
	$r->route('/session/login')->to('session#login');
	$r->route('/session/logout')->to('session#logout');
}

1;
