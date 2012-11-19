package OdenSchedule::Model::ScheduleCrawler;
##################################################
# OECUMail用スケジュールクローラー
##################################################

use strict;
use warnings;
use utf8;

use Net::OECUMailOAuth;
use Encode::IMAPUTF7;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	$self->{username} = $hash{username} || die ('Not specified username.');
	$self->{oauth_accessToken} = $hash{oauth_accessToken} || die ('Not specified oauth_accessToken.');
	return $self;
}

sub crawl {
	my $self = shift;
	my @mail_bodies = $self->getMails_();
	my @schedules = ();
	foreach my $mail (@mail_bodies){
		if($mail =~ /(\d+)月(\d+)日 (.+)曜 (\d+)時限 (.*)(\(.*\)) は休講です。/m){
			my $hash = {
				'type' => '休講',
				'month' => $1,
				'day' => $2,
				'wday' => $3,
				'period' => $4,
				'subject' => $5,
				'teacher' => $6,
			};
			push(@schedules, $hash);
		}elsif($mail =~ /(\d+)月(\d+)日 (.+)曜 (\d+)時限 (.*)(\(.*\)) は補講です。/m){
			my $hash = {
				'type' => '休講',
				'month' => $1,
				'day' => $2,
				'wday' => $3,
				'period' => $4,
				'subject' => $5,
				'teacher' => $6,
			};
			push(@schedules, $hash);
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
	my @msgs = $oecu->getIMAPObject()->search(
		'FROM "dportsys@mc2.osakac.ac.jp"',
		'SENTSINCE '.$oecu->getIMAPObject()->Rfc3501_date(time() - (60 * 60 * 24 * 31 * 2)) #条件: 2ヶ月前以降のメール
	);
	
	my @mail_bodies;
	
	foreach my $msg (@msgs) {
		my $body = $oecu->getIMAPObject()->body_string($msg) or die "Could not body_string: ", $self->{imap}->LastError;
		push(@mail_bodies, Encode::decode_utf8($body));
	}
	return @mail_bodies;
}

1;