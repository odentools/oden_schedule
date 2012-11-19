package OdenSchedule::Model::ScheduleCrawler;
##################################################
# OECUMail用スケジュールクローラー
##################################################

use strict;
use warnings;
use utf8;

sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	$self->{username} = $hash{username} || die ('Not specified username.');
	$self->{oauth_accessToken} = $hash{oauth_accessToken} || die ('Not specified oauth_accessToken.');
	return $self;
}

sub crawl {
	my $self = shift;
	my $oecu = Net::OECUMailOAuth->new(
		'username'			=>	$self->{username},
		'oauth_accessToken' =>	$self->{oauth_accessToken},
	);
	my @dirs = $oecu->getFolders();#配列？
	
}

1;