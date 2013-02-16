package OdenSchedule::Helper::Login;

use strict;
use warnings;

use base 'Mojolicious::Plugin';
use Mojo::Util;

sub register {
	my ($self, $app) = @_;
	
	# OAuth クライアント for Google
	$app->helper( oauth_client_google =>
		sub {
			return Net::OAuth2::Client->new(
				$app->config()->{social_google_key},
				$app->config()->{social_google_secret},
				site	=>	'https://accounts.google.com',
				authorize_path	=>	'/o/oauth2/auth',
				access_token_path=>	'/o/oauth2/token',
				approval_prompt	=> 'auto',
				access_type => 'offline',
				scope	=>	'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/calendar https://mail.google.com/'
			)->web_server(redirect_uri => ($app->config()->{base_url}) .'session/oauth_google_callback', access_type => 'offline');
		}
	);
	
	# OAuth リフレッシュ用クライアント for Google
	$app->helper( oauth_client_google_refresh =>
		sub {
			my $refresh_token = shift;
			return Net::OAuth2::Client->new(
				$app->config()->{social_google_key},
				$app->config()->{social_google_secret},
				refresh_token => $refresh_token,
				grant_type => 'refresh_token',
				site	=>	'https://accounts.google.com',
				authorize_path	=>	'/o/oauth2/auth',
				access_token_path=>	'/o/oauth2/token',
				approval_prompt	=> 'auto',
				scope	=>	'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/calendar https://mail.google.com/'
			)->web_server(access_type => 'offline');
		}
	);

	# セッションキーの生成
	$app->helper( make_session_key => 
		sub {
			my $seed_id = shift;

			my $time_num = time();
			my $rand_num = int(rand(99999999999999999));

			my $key = $seed_id;
			for(my $i=0;$i<10;$i++){
				$key = Mojo::Util::hmac_sha1_sum($key, $time_num + $rand_num);
			}
			$key = Mojo::Util::b64_encode($key.$time_num);
			return($key);
		}
	);
}

1;