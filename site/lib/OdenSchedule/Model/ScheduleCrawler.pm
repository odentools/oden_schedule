package OdenSchedule::Model::ScheduleCrawler;
##################################################
# OECU course schedule crawler (from OECUMail)
##################################################

use strict;
use warnings;
use utf8;

use Digest::SHA1;
use Encode::IMAPUTF7;
use Time::Piece;

use Net::OECUMailOAuth;
use Net::Google::CalendarLite; # for use only: refresh OAuth-token

# Timetable (periods)
our $PERIOD_TIME_TABLE_NEYAGAWA = {
	'1' => "09:00",
	'2' => "10:40",
	'3' => "13:00",
	'4' => "14:40",
	'5' => "16:20",
	'6' => "18:00",
	'7' => "19:40",
};
our $PERIOD_TIME_TABLE_NAWATE = {
	'1' => "09:30",
	'2' => "11:10",
	'3' => "13:30",
	'4' => "15:10",
	'5' => "16:50",
	'6' => "18:30",
	'7' => "20:10",
};

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{db}	= ${$hash{db}} || die ('Not specified db instance.');# Database instance
	$self->{own_user} = ${$hash{own_user}} || die ('Not specified own_user.');# Current user instance
	$self->{logger} = ${$hash{logger}} || die ('Not specified logger.');# Log(Mojo::Log) instance
	$self->{config} = ${$hash{config}} || die ('Not specified config.');# Config(Mojo::Plugin::Config) instance
	
	# OAuth tokens
	$self->{oauth_access_token} = $self->{own_user}->{google_token} || die ('Not specified oauth_access_token.');
	$self->{oauth_refresh_token} = $self->{own_user}->{google_reftoken} || die ('Not specified oauth_refresh_token.');
	
	# App configurations
	$self->{api_key} = $self->{config}->{social_google_apikey};
	$self->{consumer_key} = $self->{config}->{social_google_key};
	$self->{consumer_secret} = $self->{config}->{social_google_secret};
	
	# Member variable
	$self->{username} = $self->{own_user}->{student_no};
	
	return $self;
}

sub upsertCrawlToDatabase {
	my ($self, $isRetry) = @_;
	my $user_id = $self->{own_user}->{id};
	
	# Crawl schedules from OECU Mail
	my @schedules;
	eval{
		@schedules = $self->crawl();
	}; if($@){
		# if error (exam: Past expiration of access-token)
		if(!defined($isRetry)){
			$self->refreshToken_();
			$self->upsertCrawlToDatabase(1);
			return;
		}
	}
	
	# Insert events to Database
	foreach my $item(@schedules){
		my $hash_str;
		foreach(keys %$item){
			$hash_str .= $_."_".$item->{$_};
		}
		my $hash_id = Digest::SHA1::sha1_base64(Encode::encode_utf8($hash_str));
		
		my $db_iter = $self->{db}->get(schedule => {where => ['hash_id' => $hash_id]});
		if(!defined($db_iter->next)){ # NOT found on DB ... insert
			# Set other values
			$item->{user_id} = $user_id;
			$item->{hash_id} = $hash_id;
			
			# Insert to DB
			my $itemRow = $self->{db}->set(schedule => $item);
		}
	}
	
}

sub crawl {
	my $self = shift;
	$self->log_debug_("crawl()...");
	
	my @mail_bodies = $self->getMails_();
	
	my @schedules = ();
	foreach my $mail (@mail_bodies){
		my $campus_name;
		if($mail =~ /発信元：大阪電気通信大学.*(四條畷|寝屋川).*/m){
			$campus_name = $1;
			
			my $campus_timetable;
			if($campus_name eq "寝屋川"){
				$campus_timetable = $PERIOD_TIME_TABLE_NEYAGAWA;
			}elsif($campus_name eq "四條畷"){
				$campus_timetable = $PERIOD_TIME_TABLE_NAWATE;
			}
			
			$self->log_debug_("* mail\n   * campus_name = $campus_name");
			
			if($mail =~ /(\d+)月(\d+)日 (.+)曜 (\d+)時限 (.*)\((.*)\) は休講です。/m){
				my $period = $4; $period =~ tr/０-９/0-9/;
				my $time = $campus_timetable->{$period} || "";
				my $hash = {
					'type' => '休講',
					'month' => $1,
					'day' => $2,
					'wday' => $3,
					'period' => $period,
					'time' => $time,
					'date' => $self->paramToTimePiece_($1, $2, $time),
					'subject' => $5,
					'teacher' => $6,
					'campus' => $campus_name,
					'room' => ''
				};
				$self->log_debug_("    * 休講");
				push(@schedules, $hash);
			}elsif($mail =~ /以下の日程で (.*)\((.*)\) の補講を行います。(\r\n|\n\r|\n|\r)(\d+)月(\d+)日 (.+)曜 (\d+)時限 (\S+)/m){
				my $period = $7; $period =~ tr/０-９/0-9/;
				my $time = $campus_timetable->{$period} || "";
				my $hash = {
					'type' => '補講',
					'subject' => $1,
					'teacher' => $2,
					'month' => $4,
					'day' => $5,
					'wday' => $6,
					'period' => $period,
					'time' => $time,
					'date' => $self->paramToTimePiece_($4, $5, $time),
					'campus' => $campus_name,
					'room' => $8,
				};
				$self->log_debug_("    * 補講");
				push(@schedules, $hash);
			}else{
				$self->log_debug_("    * その他\n${mail}\n");
			}
		}
	}
	return @schedules;
}

sub getMails_ {
	my $self = shift;
	my $oecu = Net::OECUMailOAuth->new(
		'username'			=>	$self->{username},
		'oauth_accessToken' =>	$self->{oauth_access_token},
	);
	my @dirs = $oecu->getFolders();
	if(!$oecu->getIMAPObject()->select(Encode::encode('IMAP-UTF-7','[Gmail]/すべてのメール'))){
		die("Can't select [Gmail]/すべてのメール");
	}
	#my @msgs = ();
	my @msgs = $oecu->getIMAPObject()->search(
		'FROM','dportsys@mc2.osakac.ac.jp',
		'SENTSINCE',$oecu->getIMAPObject()->Rfc3501_date(time() - (60 * 60 * 24 * 31 * 2)) #条件: 2ヶ月前以降のメール
	);
	
	my @mail_bodies;
	
	foreach my $msg (@msgs) {
		my $body = $oecu->getIMAPObject()->body_string($msg) or die "Could not body_string: ", $self->{imap}->LastError;
		push(@mail_bodies, Encode::decode_utf8($body));
	}
	return @mail_bodies;
}

sub paramToTimePiece_ {
	my ($self, $month, $day, $time) = @_;
	# [Precondition!] Less than 5 months (+/-) from current month.
	
	$self->log_debug_("    * paramToTimePiece_ $month $day $time");
	
	my $current_t = Time::Piece::localtime();
	my $current_year = $current_t->year;
	my $next_year = $current_year + 1;
	my $before_year = $current_year - 1;
	my $current_month = $current_t->mon;
	my $year;
	
	if(abs($month - $current_month) <= 5){
		$year = $current_year;
	}else{ # before year
		if(($month - $current_month) < 0){
			$year = $next_year;
		}else{
			$year = $before_year;
		}
	}
	
	$self->log_debug_("        * $year $month $day $time");
	return Time::Piece->strptime($year.'-'.$month.'-'.$day.' '.$time.':00+0900', '%Y-%m-%d %T%z');
}

sub refreshToken_ {
	my $self = shift;
	my $gcal = Net::Google::CalendarLite->new(
		'api_key' => $self->{api_key},
		'consumer_key'	=> $self->{consumer_key},
		'consumer_secret'	=>	$self->{consumer_secret},
		'oauth_access_token'	=>	$self->{oauth_access_token},
		'oauth_refresh_token'=>	$self->{oauth_refresh_token}
	);
	$gcal->refreshToken();
	$self->{oauth_access_token} = $gcal->returnToken();
	$self->{own_user}->google_token($self->{oauth_access_token});
	$self->{own_user}->update();
}

sub log_debug_ {
	my ($self, $text) = @_;
	$self->{logger}->debug($text);
}

1;