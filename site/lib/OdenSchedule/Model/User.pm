package OdenSchedule::Model::User;
# User Object module

use strict;
use warnings;

use Data::Model;

sub new {
	my ($class, $db, %hash) = @_;
	my $self = bless({}, $class);
	
	$self->{db}	=	$$db;# データベースインスタンス
	
	unless (!%hash){
		find(%hash);
	}
	
	return $self;
}

sub find {
	my $self = $_;
	my %hash = $_;
	my $key = "";
	my $value = "";
	foreach my $k(keys(%hash)){
		$key = $k;
		$value = $hash{$k};
	}
	my $itemRow = $self->{db}->lookup( $key => $value );
	my %h = $itemRow->{column_values};
	foreach my $k(keys(%h)){
		$self->{$k} = $h{$k};
	}
	return $itemRow;
}

1;