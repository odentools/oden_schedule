package OdenSchedule::Controller::Bridge;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

# 前処理を行うブリッジ (認証セッションチェックなど)
sub login_check {
	my $self = shift;
	
	# JavaScriptによるアクセスのためのヘッダを追加
	$self->res->headers->add('Access-Control-Allow-Origin', '*');
	
	# Cookieの有効期限をセット
	$self->session(expiration=> $self->config()->{session_expires});
	
	# ユーザ情報ヘルパーをリセット (非ログイン状態をセット)
	$self->app->helper('ownUserId' => sub { return undef });
	$self->app->helper('ownUser' => sub { return undef });
	$self->stash(logined => 0);
	
	if($self->session('google_token')){ # セッションがあれば...
		my $user = $self->getUserObj('google_token' => $self->session('google_token'));
		if($user->{isFound}){
			$self->app->helper('ownUserId' => sub { return $user->{id} });
			$self->app->helper('ownUser' => sub { return $user });
			$self->stash(logined => 1);
		}
	}
	
	# ユーザが認証トークンを持っていなければ
	if($self->current_route eq "top_user"){
		$self->redirect_to('/session/login');
		return 0;
	}
	
	return 1; # continue after process (そのまま出力を続行)
}

1;