package Net::OECUMailOAuth; 
##################################################
# Net::OECUMailOAuth
# OECUMail用ライブラリモジュール IMAP & OAuth(XOAUTH2)版
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

# 参照 #####
# https://developers.google.com/google-apps/gmail/oauth_overview
#

use strict;
use warnings;
use utf8;

=head1  NAME

Net::OECUMailOAuth.pm

=head1 DESCRIPTION

OECUMail用ライブラリモジュール IMAP & OAuth(XOAUTH2)版
OECUMailへのIMAPアクセスを提供します。
認証についてはOAuth2を利用します。

=head1 SYNOPSIS

use Net::OECUMail;

my $oecu = Net::OECUMail->new(
	'oauth_token' => 'XXXXXXXXXXX'
);

my @mails = $oecu->getInbox();
foreach $i(@mails){
	print "$i->{Title} | $i->{From} | $i->{Date}";
}

=head1 FUNCTIONS

This heading is under construction.

Version 1.0.0

=head1 VERSION

Version 1.0.0

=head1 AUTHOR

(C)Masanori Ohgita. (http://ohgita.info/)

=cut

our $VERSION = '1.0.0';

use Carp;
use Encode qw(encode decode);
use URI;

use Net::OAuth;
use URI::Escape;
use MIME::Base64;
use Mail::IMAPClient;

# new(...) 	コンストラクタ
sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{username} = $hash{username}.'@oecu.jp';
	$self->{imap} = undef;
	$self->{oauth} = undef;
	$self->{oauth_sign} = undef;
	$self->{oauth_accessToken} = $hash{oauth_accessToken} || undef;
	return $self;
}

# DESTROY(...) デストラクタ
sub DESTROY{
	my $self = shift;
	if(defined($self->{imap})){
		$self->{imap}->logout;
		$self->{imap} = undef;
	}
}

sub oauthInit_ {
	my $self = shift;
	# Make OAuth authorization signature
	if(!defined($self->{oauth_sign})){
		my $sig = "user=". $self->{username} ."\x01auth=Bearer ". $self->{oauth_accessToken} ."\x01\x01";
		$self->{oauth_sign} = encode_base64($sig, '');
	}
}

sub imapInit_ {
	my $self = shift;	# IMAPClient
	if(!defined($self->{imap})){
		$self->{imap} = Mail::IMAPClient->new(
			Server	=>	'imap.gmail.com',
			Port	=>	993,
			Ssl		=> 1,
			Uid		=> 1,
		);
		my $sign = $self->{oauth_sign};
		$self->{imap}->authenticate('XOAUTH2', sub { return $sign }) or die "auth failed: ".$self->{imap}->LastError;
	}
}

sub getFolders {
	my $self = shift;
	$self->oauthInit_();
	$self->imapInit_();
	return $self->{imap}->folders or die("List folders error: ", $self->{imap}->LastError);
}

sub getIMAPObject {
	my $self = shift;
	return $self->{imap};
}


1;