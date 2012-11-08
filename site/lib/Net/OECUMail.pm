package Net::OECUMail; 
##################################################
# Net::OECUMail
# OECUMail用ライブラリモジュール
# (C)Masanori Ohgita. (http://ohgita.info/)
##################################################

use strict;
use warnings;
use utf8;

=head1  NAME

Net::OECUMail.pm

=head1 DESCRIPTION

OECUMail用ライブラリモジュール。
OECUMailへの認証機能、Eメールの送受信機能を提供します。

=head1 SYNOPSIS

use Net::OECUMail;

my $oecu = Net::OECUMail->new(
	'username' => 'ht00a000',
	'password' => '12345678'
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

use Net::POP3;
use Net::POP3::SSLWrapper;

# new(...) 	コンストラクタ
sub new {
	my ($class, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{username} = $hash{username}.'@oecu.jp';
	$self->{password} = $hash{password};
	$self->{pop3} = undef;
	
	return $self;
}

# login(...)	ログイン実行
sub login {
	my $self = shift;
	pop3s {
		if(!defined($self->{pop3})){
			#Net::POP3でサーバ接続
			$self->{pop3} = Net::POP3->new('pop.gmail.com', Port=>'995', Timeout => 10) or die("Can't connect.");
		}
		#メールサーバ認証を行い、メール数を取得
		my $count = $self->{pop3}->login($self->{username}, $self->{password});
		if(!defined($count) || $count < 0){
			die("Can't login.");
		}
		$self->{pop3}->quit;
	};
	return 1;
}

1;