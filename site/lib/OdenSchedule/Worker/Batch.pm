package OdenSchedule::Worker::Batch;

use strict;
use warnings;
use utf8;

use OdenSchedule::Model::User;
use OdenSchedule::Model::ScheduleCrawler;
use OdenSchedule::Model::CalendarOrganizer;

sub new {
	my ($class, $app, $db) = @_;
	my $self = bless({}, $class);
	
	$self->{app}= $$app;
	$self->{db}	= $$db;
	
	$self->{batch_interval} = $self->{app}->config->{batch_interval} || die('Not specified batch_interval');
	
	$self->{app}->log->debug("-----Worker::Batch-----");
	
	#$self->runBatch();
	
	return $self;
}

sub runBatch {
	my $self = shift;
	$self->{app}->log->debug("runbatch() - ".time());
	
	# Iterate all users from DB
	my $iter = $self->{db}->get(user => 1);
	while(my $row = $iter->next){
		my $item = $row->{column_values};
		
		if( $item->{latest_batch_time} eq "" 
			|| $item->{latest_batch_time} <= (time() -  $self->{batch_interval}) 
		){# If time passes interval from the last processing ...
			$self->{app}->log->debug("    * Run batch: user.id = ".$item->{id});
			
			my $user_object = OdenSchedule::Model::User->new( \($self->{db}), \($self->{app}->log), {'id'=>$item->{id}} );
			$user_object->latest_batch_time(time());
			$user_object->update();
			
			# 休講・補講情報の取得
			eval{
				my $crawler = OdenSchedule::Model::ScheduleCrawler->new(
					'db' => \($self->{db}),
					'own_user' => \$user_object,
					'logger' => \($self->{app}->log),
					'config' => \($self->{app}->config),
				);
				$crawler->upsertCrawlToDatabase();
			};
			if($@){
				$self->{app}->log->error("BatchErrorA:\n".$@);
				next;
			}
			
			# カレンダーの登録＆更新
			eval{
				my $calorg = OdenSchedule::Model::CalendarOrganizer->new(
					'db' => \($self->{db}),
					'own_user' => \$user_object,
					'logger' => \($self->{app}->log),
					'config' => \($self->{app}->config),
				);
				$calorg->upsertDatabaseToCalendar();
			};
			if($@){
				$self->{app}->log->error("BatchErrorB:\n".$@);
				next;
			}
			$self->{app}->log->debug("    * Complete batch: user.id = ".$item->{id});			
		}
	}
}

1;