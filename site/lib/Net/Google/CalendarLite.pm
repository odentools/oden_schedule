package Net::Google::CalendarLite;
##################################################
# Net::Google::CalendarLite - Googleカレンダーを扱う簡易モジュール
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

=head1 SCRIPT NAME

Net::Google::CalendarLite

=head1 DESCRIPTION

Googleカレンダーを扱う簡易モジュール

=cut

use strict;
use warnings;
use utf8;
use Encode;

our $VERSION = '1.0.0';

use Carp;

use JSON;
use LWP::UserAgent;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{api_key}			= $hash{api_key} || "";
	$self->{consumer_key} 		= $hash{consumer_key} || "";
	$self->{consumer_secret}	= $hash{consumer_secret} || "";
	$self->{oauth_access_token}		= $hash{oauth_access_token} || "";
	$self->{oauth_refresh_token}		= $hash{oauth_refresh_token} || "";
	$self->{ua}					= LWP::UserAgent->new;
	$self->{ua}->timeout(20);
	$self->{json}				= JSON->new;
	
	return $self;
}

sub getCalendarList {
	my $self = shift;
	my $noRetry = shift || 0;
	
	my $res = $self->{ua}->get('https://www.googleapis.com/calendar/v3/users/me/calendarList?minAccessRole=writer&key='.$self->{api_key}, Authorization => 'Bearer '. $self->{oauth_access_token});
	if($res->is_success){
		return $self->{json}->decode(Encode::decode_utf8($res->content))->{items};
	}elsif($noRetry ne 1){
		$self->refreshTokens();
		return $self->getCalendarList(1);
	}else{
		return undef;
	}
}

sub refreshTokens {
	my $self = shift;
	my $oauth = Net::OAuth2::Client->new(
		$self->{consumer_key},
		$self->{consumer_secret},
		refresh_token => $self->{oauth_refresh_token},
		grant_type => 'refresh_token',
		site	=>	'https://accounts.google.com',
		authorize_path	=>	'/o/oauth2/auth',
		access_token_path=>	'/o/oauth2/token',
		access_type => 'offline',
		approval_prompt	=> 'auto',
		scope	=>	'https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/calendar https://mail.google.com/'
	)->web_server();
	my $access_token = $oauth->get_access_token($self->{oauth_refresh_token});
	$self->{oauth_access_token} = $access_token->{access_token};
	$self->{oauth_refresh_token} = $access_token->{refresh_token};
}

1;