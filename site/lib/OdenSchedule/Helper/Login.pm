package OdenSchedule::Helper::Login;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

sub register {
	my ($self, $app) = @_;
	
	# OAuth Client for Google
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
	
	# OAuth Refresh Client for Google
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
}

1;