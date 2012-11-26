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
	$self->redirect_to($oauth->authorize_url(access_type => 'offline', approval_prompt => 'force'));
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
		$self->flash('message_error','認証に失敗しました。再度ログインしてください。');
		$self->redirect_to('/session/login/?token_invalid');
		$self->app->log->debug("Login: token_invalid:".$@);
		return;
	}
	
	# ユーザ情報を取得
	my $response = $access_token->get('https://www.googleapis.com/oauth2/v1/userinfo');
	if ($response->is_success) {
		my $profile = Mojo::JSON->decode($response->decoded_content());
		my $user_id = $profile->{email};
		
		# OECUメールアカウントからのログインであるかどうかを確認
		my $is_login_oecu = 0;
		if($user_id =~ /.+\@oecu\.jp/){# OECUメールアカウントならば
			$self->app->log->fatal("DEBUG:Session - OECU-account login...".$user_id);
			 $is_login_oecu = 1;
		}else{
			$self->app->log->fatal("DEBUG:Session - Not OECU-account login...".$user_id);
		}
		
		# アクセストークン
		my $token = $access_token->{access_token};
		my $ref_token = $access_token->{refresh_token};
		$self->app->log->fatal("DEBUG:Session - token = ".$token);
		
		if(defined($self->ownUserId()) && $is_login_oecu eq 0){ # すでにログイン中 && 今がGoogleアカウントからのログインならば...
			# サブアカウント(Googleアカウント)追加のためのログイン処理 -----
			my $user = $self->ownUser;
			$self->app->log->fatal("DEBUG:Session - [saA] login...".$user_id." -> ". $self->ownUserId() ." - ". $user->{oecu_id});
			$user->google_id($user_id);
			$user->google_token($token);
			$user->google_reftoken($ref_token);
			$user->latest_auth_time(time());
			$user->update();
			
			# セッションはそのままリダイレクト
			$self->redirect_to("/top");
			return;
		}
		
		# 通常のログイン処理 -----
		
		if($is_login_oecu eq 0){# 今がGoogleアカウントからのログインならば...
			$self->app->log->fatal("DEBUG:Session - [saB] Google account block");
			$self->flash("message_error", "<em>おでん助は、Googleアカウントではログインできません。</em><br>一旦、Googleからログアウトした後、OECUメールのアカウントでログインしなおしてください。");
			$self->redirect_to('/session/login/?account_not_oecu');
			return;
		}
		
		# ユーザを検索
		my $user = $self->getUserObj('oecu_id' => $user_id);
		$self->app->log->fatal("DEBUG:Session - Normal login...".$user_id);
		if($user->{isFound}){# 既存ユーザであれば...
			$self->app->log->fatal("DEBUG:Session - [nomA] $user_id - isFound = 1 ... ".$user->{id}." ... ".$user->{oecu_id});
			$user->oecu_token($token);
			$user->oecu_reftoken($ref_token);
			$user->session_token($token);
			$user->latest_auth_time(time());
			$user->update();
		} else {# 新規ユーザであれば...
			$self->app->log->fatal("DEBUG:Session - [nomB] $user_id - isFound = 0 ...");
			$user->set(
				name => $user_id,
				oecu_id => $user_id,
				oecu_token => $token,
				oecu_reftoken => $ref_token,
				session_token => $token,
				latest_auth_time => time(),
				batch_mode => 1,
				student_no => substr($user_id, 0, rindex($user_id, '@'))
			);
		}
		# セッションを保存してリダイレクト
		$self->session('session_token', $token);
		$self->redirect_to("/");
		
	} else { # ユーザ情報が取得できなければ...
		$self->flash('message_error','ユーザ情報の取得に失敗しました。再度ログインしてください。');
		$self->redirect_to('/session/login');
	}
}

sub login {
	my $self = shift;
	if(defined($self->flash("message_error"))){
		$self->stash("message_error", $self->flash("message_error"));
	}
	$self->render();
}

sub logout {
	my $self = shift;
	
	# セッションをクリア
	$self->session(expires => 1);
	
	# リダイレクト
	$self->redirect_to('/');
}

1;
