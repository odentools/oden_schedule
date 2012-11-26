package OdenSchedule::Model::CalendarOrganizer;
##################################################
# Calendar organizer model module
# (It's currently use for Database <-> Google-Calendar.)
##################################################

use strict;
use warnings;
use utf8;

use Encode;
use Net::Google::CalendarLite;
use Mojo::JSON;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{db}	= ${$hash{db}} || die ('Not specified db instance.');# Database instance
	$self->{own_user} = ${$hash{own_user}} || die ('Not specified own_user.');# Current user instance
	$self->{logger} = ${$hash{logger}} || die ('Not specified logger.');# Log(Mojo::Log) instance
	$self->{config} = ${$hash{config}} || die ('Not specified config.');# Config(Mojo::Plugin::Config) instance
	
	# OAuth tokens
	if(defined($self->{own_user}->{google_id})){
		$self->{oauth_access_token} = $self->{own_user}->{google_token} || die ('Not specified oauth_accessToken.');
		$self->{oauth_refresh_token} = $self->{own_user}->{google_reftoken} || die ('Not specified oauth_refresh_token.');
	}else{
		$self->{oauth_access_token} = $self->{own_user}->{oecu_token} || die ('Not specified oauth_accessToken.');
		$self->{oauth_refresh_token} = $self->{own_user}->{oecu_reftoken} || die ('Not specified oauth_refresh_token.');
	}
	
	# App configurations
	$self->{api_key} = $self->{config}->{social_google_apikey};
	$self->{consumer_key} = $self->{config}->{social_google_key};
	$self->{consumer_secret} = $self->{config}->{social_google_secret};
	
	# Member objects
	$self->{gcal} = undef;
	
	return $self;
}

# Insert/Update the event into Google-Calendar from Database
sub upsertDatabaseToCalendar {
	my $self = shift;
	$self->log_debug_("CalendarOrganizer::update()...");
	
	# Decision database id
	my $calendar_id = $self->{own_user}->{calendar_id_gcal};
	
	# Gather events from Database
	my @schedule_rows;
	my $iter = $self->{db}->get(schedule => {where => ['user_id' => $self->{own_user}->{id}]});
	while(my $row = $iter->next){
		push(@schedule_rows, $row);
	}
	
	foreach my $row(@schedule_rows){
		my $item = $row->{column_values};
		if($item->{gcal_cid} eq $calendar_id && $item->{gcal_eid} ne ""){
			# if this event was already inserted this calendar...
			next;
		}
		
		# Build insert event-data
		my %hash = (
			calendarId => $calendar_id,
			summary => Encode::encode_utf8($item->{subject}." [".$item->{type}."]"),
			location => Encode::encode_utf8("大阪電気通信大学 ".$item->{campus}." ".$item->{room}),
			description => Encode::encode_utf8("$item->{subject}\n$item->{teacher}\n$item->{date} $item->{type}\nby おでん助"),			
			start => {
				dateTime => $item->{date}->datetime,
				timeZone => 'Asia/Tokyo'
			},
			end => {
				dateTime => $item->{date}->datetime,
				timeZone => 'Asia/Tokyo'
			}
		);
		$self->log_debug_("insertEvent:".Mojo::JSON->encode(\%hash));
		
		# Insert event-data to Google-Calendar
		my $event_id;
		eval{
			$event_id = $self->insertEvent(%hash); 
		};
		if($@){
			$self->log_debug_("error!".$@);
		}
		$self->log_debug_("inserted:".$event_id);
		
		# Update event on database
		$row->gcal_cid($calendar_id);
		$row->gcal_eid($event_id);
		$row->update();
	}
}

# Request getCalendarList to Google-Calendar 
sub getCalendarList {
	my $self = shift;
	$self->initGcal_();
	return $self->{gcal}->getCalendarList();
}

# Request insertEvent to Google-Calendar
sub insertEvent {
	my ($self, %param) = @_;
	$self->initGcal_();
	return $self->{gcal}->insertEvent(%param);
}

sub initGcal_{
	my $self = shift;
	if(!defined($self->{gcal})){
		$self->{gcal} = Net::Google::CalendarLite->new(
			'api_key' => $self->{api_key},
			'consumer_key'	=> $self->{consumer_key},
			'consumer_secret'	=>	$self->{consumer_secret},
			'oauth_access_token'	=>	$self->{oauth_access_token},
			'oauth_refresh_token'=>	$self->{oauth_refresh_token}
		);
	}
}

sub log_debug_ {
	my ($self, $text) = @_;
	$self->{logger}->debug($text);
}

1;