package OdenSchedule::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

use Net::OECUMailOAuth;

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
	
	my $oecu = Net::OECUMailOAuth->new( 'username' =>'ht11a018', 'token' =>$self->ownUser->{google_token} );
	my $imap_folders;
	eval{
		$imap_folders = join("<br>",$oecu->getFolders());
	};
	if($@){
		$imap_folders = $@;
	}
	$self->stash('folders',$imap_folders);
	$self->stash( 'isUser_google', 1 );
	$self->render();
}

1;
