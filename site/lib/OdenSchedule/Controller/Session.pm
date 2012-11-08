package OdenSchedule::Controller::Session;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

sub oauth_google_redirect {
	my $self = shift;
	
	# ヘルパー(Helper::Login)をロード
	$self->app->plugin('OdenSchedule::Helper::Login');
	
	# Net::OAuth2::Clientのインスタンスを初期化
	my $oauth = $self->oauth_client_google;
	
	# 認証ページへリダイレクト
	$self->redirect_to($oauth->authorize_url);
}

sub oauth_google_callback {
	my $self = shift;
	
	# ヘルパー(Helper::Login)をロード
	$self->app->plugin('OdenSchedule::Helper::Login');
	
	# Net::OAuth2::Clientのインスタンスを初期化
	my $oauth = $self->oauth_client_google;
	
	# トークンを取得
	my $access_token;
	eval {
		$access_token = $oauth->get_access_token($self->param('code'));
	};
	
	if($@){
		$self->redirect_to('/?token_invalid');
		return;
	}
	
	# ユーザ情報を取得
	my $response = $access_token->get('https://www.googleapis.com/oauth2/v1/userinfo');
	if ($response->is_success) {
		my $profile = Mojo::JSON->decode($response->decoded_content());
		my $user_id = $profile->{email};
		my $token = $access_token->{access_token};
		
		my $user = $self->getUser('google_token' => $user_id);
		if(defined($user)){# 既存ユーザであれば...
			$user->google_id($user_id);
			$user->google_token($token);
			$user->update();
		} else {# 新規ユーザであれば...
			my $user = {
				name					=> $user_id,
				google_id				=> $user_id,
				google_token			=> $token
			};
			$self->user->addUser($user);
		}
		# セッションを保存してリダイレクト
		$self->session('google_token', $token);
		$self->redirect_to("/");	
	} else {
		$self->flash('message_error','認証に失敗しました。');
		$self->redirect_to('/session/login');
	}
}

sub login {
	my $self = shift;
	my $message = "";
	if($self->flash("message_error") ne ""){
		$message = $self->flash("message_error");
	}
	$self->render( message => $message );
}

1;
