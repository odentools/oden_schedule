package OdenSchedule::Model::User;
# User Object module

use strict;
use warnings;

use Data::Model;

sub new {
	my ($class, $db, $log, %hash) = @_;
	my $self = bless({}, $class);
	
	$$log->debug("Model::User - new(...)");
	
	$self->{db}	=	$$db;# データベースインスタンス
	
	$self->{log} = $$log;
	
	$self->{itemRow} = undef;
	
	unless (!%hash){ # 検索条件ハッシュが指定されていれば...ユーザ検索
		$$log->debug("Model::User - specified hash");
		if(! defined($self->find(%hash))){ #ユーザが存在しなければ
			return undef;
		}
	}
	return $self;
}

sub find {
	my $self = shift;
	my %hash = shift;
	$self->{log}->debug("Model::User - find(...)");
	my $key = "";
	my $value = "";
	foreach my $k(keys(%hash)){
		$key = $k;
		$value = $hash{$k};
	}
	my $iter = $self->{db}->get(user => {where => [$key => $value]});
	my $itemRow = $iter->next;
	if(($itemRow)){
		$self->{log}->debug(" * found user");
		$self->applyObject($itemRow);
		return $itemRow;
	}elsif($self->{isFindOrCreate}) {
		$self->{log}->debug(" * user not found, isFindOrCreate = true");
		$self->{log}->debug(" * set user");
		
		$self->applyObject($itemRow);
		return $itemRow;
	}else{
		$self->{log}->debug(" * user not found");
		return undef;
	}
}

sub set {
	my ($self, %hash) = @_;
	my $itemRow = $self->{db}->set(user => %hash);
	return $itemRow;
}

sub update {
	my ($self, $key, $value) = @_;
	$self->{log}->debug("Model::User - update(...)");
	my $hash = $self->{itemRow}->{column_values};
	my $itemRow = $self->{db}->update(
		user => $self->{id} => undef => $hash
	);
	$self->applyObject($itemRow);
}

sub delete {
	my $self = shift;
	$self->{log}->debug("Model::User - delete(...)");
	if(defined($self->{itemRow})){
		my $u = $self->{db}->get(user => {where => [_id => $self->{itemRow}->_id]})->next;
	} 
}

sub applyObject {
	my $self = shift;
	my $itemRow = shift;
	$self->{log}->debug("Model::User - applyObject(...)");
	my %h = $itemRow->{column_values};
	foreach my $k(keys(%h)){
		# メンバ変数として登録
		$self->{$k} = $h{$k};
		# メンバ関数として登録
		my $mes = sub { my $self=shift; my $val=shift; $self->update($self->{$k}, $val);};
		*{ $k } = $mes;
	}
}

1;