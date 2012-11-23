package OdenSchedule::Model::ScheduleCrawler;
##################################################
# OECUMail用スケジュールクローラー
##################################################

use strict;
use warnings;
use utf8;

use Net::OECUMailOAuth;
use Encode::IMAPUTF7;
use Time::Piece;

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
	$self->{username} = $hash{username} || die ('Not specified username.');
	$self->{oauth_accessToken} = $hash{oauth_accessToken} || die ('Not specified oauth_accessToken.');
	$self->{logs} = "";
	return $self;
}

sub crawl {
	my $self = shift;
	$self->log_("crawl()...");
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
			
			$self->log_("* mail\n   * campus_name = $campus_name");
			
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
				$self->log_("    * 休講");
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
				$self->log_("    * 補講");
				push(@schedules, $hash);
			}else{
				$self->log_("    * その他\n${mail}\n");
			}
		}
	}
	return @schedules;
}

sub getMails_ {
	my $self = shift;
	my $oecu = Net::OECUMailOAuth->new(
		'username'			=>	$self->{username},
		'oauth_accessToken' =>	$self->{oauth_accessToken},
	);
	my @dirs = $oecu->getFolders();#配列？
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
	
	$self->log_("    * paramToTimePiece_ $month $day $time");
	
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
	
	$self->log_("        * $year $month $day $time");
	return Time::Piece->strptime($year.'-'.$month.'-'.$day.' '.$time.':00+0900', '%Y-%m-%d %T%z');
}

sub log_ {
	my $self = shift;
	my $text = shift;
	$self->{logs} .= $text."\n";
}

1;