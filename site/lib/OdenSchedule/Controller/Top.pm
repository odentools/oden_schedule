package OdenSchedule::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

use Net::OECUMailOAuth;
use OdenSchedule::Model::ScheduleCrawler;
use OdenSchedule::Model::CalendarOrganizer;
use Net::Google::CalendarLite;

sub top_guest {
	my $self = shift;
	if ( $self->ownUserId() ne "" ) {
		$self->redirect_to("/top");
		return;
	}
	$self->render();
}

sub top_user {
	my $self = shift;
	
	if(defined($self->flash("message_info"))){
		$self->stash("message_info", $self->flash("message_info"));
	}
	
	if(defined($self->param('set_calendar_id'))){
		$self->ownUser->calendar_id_gcal($self->param('set_calendar_id'));
		$self->ownUser->update();
		$self->render_json({status => 1, calendar_id => $self->param('set_calendar_id')});
		return;
	}
	
	# Event list
	my @schedules;
	my $iter = $self->db->get(schedule => {
		where => ['user_id' => $self->ownUser->{id}]
	});
	while(my $item = $iter->next){
		my $hash = $item->{column_values};
		$hash->{date_str} = $hash->{date};
		push(@schedules, $hash);
	}
	@schedules = sort { $a->{date} <=> $b->{date} } @schedules;
	$self->stash('schedules', \@schedules);
	
	# Calendars list
	my $calorg = OdenSchedule::Model::CalendarOrganizer->new(
		'db' => \($self->app->db),
		'own_user' => \($self->ownUser),
		'logger' => \($self->app->log),
		'config' => \($self->config),
	);
	
	$self->stash('calendars', []);
	eval{
		# Fetch the calendars list with oauth-account
		my @calendars = $calorg->getCalendarList();
		$self->stash('calendars', \@calendars);
		
		if($self->ownUser->{calendar_id_gcal} eq "" || defined($self->flash('calendar_reselect'))){
			# Automatic re-select the calendar
			$self->ownUser->calendar_id_gcal($calendars[0]->{id});
			$self->ownUser->update();
			
		}else{
			# Check selected-calendar is available
			my $flg_found_calendar = 0;
			foreach my $cal(@calendars){
				if($self->ownUser->{calendar_id_gcal} eq $cal->{id}){ $flg_found_calendar = 1; last; }
			}
			if($flg_found_calendar eq 0){ # If must do re-selection of calendar...
				$self->flash('calendar_reselect','true');
				$self->flash('message_info', "自動登録先のカレンダーが自動的に再選択されました。 ");
				$self->redirect_to('/top');
			}
		}
	}; $self->stash('message_error', $@) if($@);
	
	$self->stash('selected_calendar_id', $self->ownUser->{calendar_id_gcal});
	
	$self->stash( 'isUser_google', 1 );
	$self->render();
}

1;
