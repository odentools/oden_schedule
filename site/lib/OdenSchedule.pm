package OdenSchedule;
use Mojo::Base 'Mojolicious';

use MongoDB;
use Data::Model;
use Data::Model::Driver::MongoDB;

use Net::OECUMail;

use OdenSchedule::DBSchema;

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
	
	# ユーザ情報ヘルパーのセット
	$self->helper('ownUserId' => sub { return undef });
	$self->helper('ownUser' => sub { return undef });
	$self->stash(logined => 0);
	
	# 前処理を行うブリッジ (認証セッションチェックなど)
	$r = $r->bridge->to('bridge#login_check');
	
	# 通常のルート
	$r->route('')->to('top#top',);
	$r->route('/docs/about')->to('docs#about',);
	$r->route('/user/edit')->to('user#edit',);
	$r->route('/login')->to('session#login');
	$r->route('/logout')->to('session#logout');
}

1;
