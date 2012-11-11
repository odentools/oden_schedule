package OdenSchedule::Model::User;
# User Object module

use strict;
use warnings;

use Mojo::JSON;

use Data::Model;

sub new {
	my ($class, $db, $log, %hash) = @_;
	my $self = bless({}, $class);
	
	$$log->debug("Model::User - new(...)");
	
	$self->{db}	=	$$db;# データベースインスタンス
	
	$self->{log} = $$log;
	
	$self->{itemRow} = undef;
	
	$self->{isFound} = undef;
	
	unless (!%hash){ # 検索条件ハッシュが指定されていれば...ユーザ検索
		$$log->debug("Model::User - specified hash");
		$self->find(%hash);
	}
	
	return $self;
}

sub find {
	my ($self, $hash) = @_;
	$self->{log}->debug("Model::User - find(...)");
	my $key = "";
	my $value = "";
	foreach my $k(keys(%$hash)){
		$key = $k;
		$value = $hash->{$k};
	}
	my $iter = $self->{db}->get(user => {where => [$key => $value]});
	my $itemRow = $iter->next;
	if(($itemRow)){
		$self->{log}->debug(" * found user: ".$itemRow->id);
		$self->{isFound} = 1;
		$self->applyObject($itemRow->{column_values});
		return $itemRow;
	}else{
		$self->{log}->debug(" * user not found");
		$self->{isFound} = undef;
		return undef;
	}
}

sub set {
	my ($self, %hash) = @_;
	$self->{log}->debug("Model::User - set(...)");
	
	my $itemRow = $self->{db}->set(user => %hash);
	$self->applyObject($itemRow->{column_values});
	return $itemRow;
}

sub update {
	my ($self, $key, $value) = @_;
	$self->{log}->debug("Model::User - update(...)");
	
	my $hash = $self->{itemRow}->{column_values};
	my $itemRow = $self->{db}->update(
		user => $self->{id} => undef => $hash
	);
	$self->applyObject($itemRow->{column_values});
}

sub delete {
	my $self = shift;
	$self->{log}->debug("Model::User - delete(...)");
	
	if(defined($self->{itemRow})){
		my $u = $self->{db}->get(user => {where => [_id => $self->{itemRow}->_id]})->next;
	} 
}

sub applyObject {
	my ($self, $h) = @_;
	$self->{log}->debug("Model::User - applyObject(...)");
	$self->{log}->debug(Mojo::JSON->encode($h));
	foreach my $k(keys(%$h)){
		my $val = $h->{$k};
		if($k eq "_id"){
			next;
		}
		# メンバ変数として登録
		$self->{$k} = $val;
		# メンバ関数として登録
		no strict 'refs';
		*{$k} = sub { my $self=shift; my $val=shift; $self->update($self->{$k}, $val);}; 
	}
}

1;