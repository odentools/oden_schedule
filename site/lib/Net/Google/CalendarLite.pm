package Net::Google::CalendarLite;
##################################################
# Net::Google::CalendarLite
# minimal client module for Google Calendar API
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

=head1 NAME

Net::Google::CalendarLite

=head1 DESCRIPTION

Minimal client module for Google Calendar API

=head1 SYNOPSIS

=head1 CONSTRUCTOR METHODS

=over

=item Net::Google::CalendarLite->new(...)

 my $ca = Net::Google::CalendarLite->new(
 	api_key => 'YOUR_API_KEY',
 	consumer_key => 'YOUR_OAUTH2_CONSUMER_KEY',
 	consumer_secret => 'YOUR_OAUTH2_CONSUMER_SECRET',
 	oauth_access_token => 'YOUR_OAUTH2_ACCESS_TOKEN',
 	oauth_refresh_token => 'YOUR_OAUTH2_REFRESH_TOKEN'
 );

=back

=head1 REQUEST METHODS

=over

=item $calendar->getCalendarList()

https://developers.google.com/google-apps/calendar/v3/reference/calendarList/list

return: @calendarList

  my @calendars = $ca->getCalendarList();
  foreach (@calendars){
  	print "$item->{id} \n";
  }

=item $calendar->insertEvent(%param)

https://developers.google.com/google-apps/calendar/v3/reference/events/insert

return: $eventId

  $ca->insertEvent(
  	calendarId => 'CALENDAR_ID',
  	start => (
  		dateTime => '2013-01-01T00:00:00'
  	)
  );

=back

=head1 AUTHOR

Masanori Ohgita, http://ohgita.info/

=head1 COPYRIGHT AND LICENSE

Copyright (C) Masanori Ohgita - 2012.

This library is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use utf8;

our $VERSION = '1.0.0';

use Carp;

use Encode;
use JSON;
use Mojo::Util;
use LWP::UserAgent;
use Net::OAuth2::Client;
use Net::OAuth2::AccessToken;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{api_key}			= $hash{api_key} || die ('Not specified api_key.');
	$self->{consumer_key} 		= $hash{consumer_key} || die ('Not specified consumer_key.');
	$self->{consumer_secret}	= $hash{consumer_secret} || die ('Not specified consumer_secret.');
	$self->{oauth_access_token}	= $hash{oauth_access_token} || die ('Not specified oauth_accessToken.');
	$self->{oauth_refresh_token}= $hash{oauth_refresh_token} || die ('Not specified oauth_refresh_token.');
	
	# Initialize user-agent
	$self->{ua}	= LWP::UserAgent->new;
	$self->{ua}->timeout(20);
	
	# Initialize JSON parser
	$self->{json} = JSON->new;
	
	return $self;
}

# Get Calendar list (return: @calendarList)
# https://developers.google.com/google-apps/calendar/v3/reference/calendarList/list
sub getCalendarList {
	my $self = shift;
	my $noRetry = shift || 0;
	my $res = $self->{ua}->get('https://www.googleapis.com/calendar/v3/users/me/calendarList?minAccessRole=writer&key='.$self->{api_key}, Authorization => 'Bearer '. $self->{oauth_access_token});
	if($res->is_success){
		my @a = $self->{json}->decode(Encode::decode_utf8($res->content))->{items};
		my @arr = ();
		foreach my $i ($a[0]){
			foreach my $i_(@$i[0]){
				push(@arr, $i_);
			}
		}
		return @arr;
	}elsif($noRetry ne 1){
		$self->refreshToken();
		return $self->getCalendarList(1);
	}else{
		return undef;
	}
}

# Insert event (return: eventId)
# https://developers.google.com/google-apps/calendar/v3/reference/events/insert
sub insertEvent{
	my ($self, %param) = @_;
	my $calendarId = $param{calendarId};
	my $noRetry = 0; if(defined($param{noRetry})){$noRetry = $param{noRetry}; delete($param{noRetry});}
	delete($param{calendarId});
	my $body = $self->{json}->encode(\%param);
	my $res = $self->{ua}->post(
		'https://www.googleapis.com/calendar/v3/calendars/'.$calendarId.'/events?key='.$self->{api_key},
		'Content-Type' => 'application/json', Authorization => 'Bearer '. $self->{oauth_access_token}, Content => $body
	);
	
	if($res->is_success){
		return $self->{json}->decode(Encode::decode_utf8($res->content))->{id};
	}elsif($noRetry ne 1){
		$self->refreshToken();
		$param{noRetry} = 1;
		$param{calendarId} = $calendarId;
		return $self->insertEvent(%param);
	}else{
		die("REQ:\n".$res->request->as_string."\nRES:\n".$res->as_string);
		return undef;
	}
}

sub refreshToken {
	my $self = shift;
	my $oauth = Net::OAuth2::Client->new(
		$self->{consumer_key},
		$self->{consumer_secret},
		site	=>	'https://accounts.google.com',
		authorize_path	=>	'/o/oauth2/auth',
		access_token_path=>	'/o/oauth2/token',
	)->web_server();
	my $access_token =  $oauth->get_access_token($self->{oauth_refresh_token} ,grant_type => "refresh_token");
	$self->{oauth_access_token} = $access_token->{access_token};
	return;
}

sub returnToken {
	my $self = shift;
	return $self->{oauth_access_token};
}

1;

