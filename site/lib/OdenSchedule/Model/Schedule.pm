package OdenSchedule::Model::Schedule;
# Schedule Object module

use strict;
use warnings;

use Mojo::JSON;

use Data::Model;

sub new {
	my ($class, $db, $log, $hash) = @_;
	my $self = bless({}, $class);
	
	$$log->debug("Model::Schedule - new(...)");
	
	$self->{db}	=	$$db;# データベースインスタンス
	
	$self->{log} = $$log;
	
	$self->{itemRow} = undef;
	
	$self->{isFound} = undef;
	
	unless (!$hash){ # 検索条件ハッシュが指定されていれば...検索
		$$log->debug("Model::Schedule - specified hash");
		$self->find($hash);
	}
	
	return $self;
}

sub AUTOLOAD{
	our $AUTOLOAD;
	my ($self, $value) = @_;
	$self->{log}->debug("Model::Schedule - AUTOLOAD(...)");
	if($AUTOLOAD eq 'OdenSchedule::Model::Schedule::DESTROY'){	return; }
	
	my $key = $AUTOLOAD;
	$key =~ s/OdenSchedule::Model::Schedule:://;
	$self->column_update($key, $value);
}

sub find {
	my ($self, $hash) = @_;
	$self->{log}->debug("Model::Schedule - find(...)");
	my $key = "";
	my $value = "";
	foreach my $k(keys %$hash){
		$key = $k;
		$value = $hash->{$k};
	}
	$self->{log}->debug(" * $key = $value");
	my $iter = $self->{db}->get(schedule => {where => [$key => $value]});
	my $itemRow = $iter->next;
	if(($itemRow)){
		$self->{log}->debug(" * found schedule: ".$itemRow->id);
		$self->{itemRow} = $itemRow;
		$self->{isFound} = 1;
		$self->applyObject($itemRow->{column_values});
		return $itemRow;
	}else{
		$self->{log}->debug(" * schedule not found");
		$self->{itemRow} = undef;
		$self->{isFound} = undef;
		return undef;
	}
}

sub set {
	my ($self, %hash) = @_;
	$self->{log}->debug("Model::Schedule - set(...)");
	$self->{log}->debug(Mojo::JSON->encode(\%hash));
	
	my $itemRow = $self->{db}->set(schedule => \%hash);
	$self->applyObject($itemRow->{column_values});
	return $itemRow;
}

sub update {
	my ($self) = shift;
	$self->{log}->debug("Model::Schedule - update(...)");
	my $itemRow = $self->{itemRow};
	my $hash = $itemRow->{column_values};
	
	$self->{log}->debug(Mojo::JSON->encode($hash));
	
	# TODO update_directは実装されていないようなので不使用とする。
	#$self->{db}->update(
	#	schedule => $hash->{id} => undef => $hash
	#);
	
	#	代わりに、itemRowに対して直接update()メソッドを呼ぶ。
	$itemRow->update();
	
	#$self->{itemRow} = $itemRow;
	$self->applyObject($itemRow->{column_values});
}

sub column_update {
	my ($self, $key, $value) = @_;
	$self->{log}->debug("Model::Schedule - column_update(...)");
	$self->{log}->debug(" * $key => $value");
	my $itemRow = $self->{itemRow};
	my $hash = $itemRow->{column_values};
	$hash->{$key} = $value;
	eval("\$itemRow->$key(\$value)");
	$self->{itemRow} = $itemRow;
	$self->applyObject($itemRow->{column_values});
}

sub delete {
	my $self = shift;
	$self->{log}->debug("Model::Schedule - delete(...)");
	
	if(defined($self->{itemRow})){
		my $u = $self->{db}->get(schedule => {where => [_id => $self->{itemRow}->_id]})->next;
	} 
}

sub applyObject {
	my ($self, $h) = @_;
	$self->{log}->debug("Model::Schedule - applyObject(...)");
	$self->{log}->debug(Mojo::JSON->encode($h));
	foreach my $k(keys %$h){
		my $val = $h->{$k};
		if($k eq "_id"){
			next;
		}
		# メンバ変数として登録
		$self->{$k} = $val;
		# メンバ関数として登録
		no strict 'refs';
		*{$k} = sub { my $self=shift; my $val=shift; $self->column_update($k, $val);}; 
	}
}

1;