package OdenSchedule;
use Mojo::Base 'Mojolicious';
use Mojo::IOLoop;

use MongoDB;
use Data::Model;
use Data::Model::Driver::MongoDB;

use Net::OECUMail;
use Net::OAuth2;
use Net::OAuth2::Client;
use Digest::SHA1;
use Time::Piece ();

use OdenSchedule::DBSchema;
use OdenSchedule::Model::User;
use OdenSchedule::Model::Schedule;
use OdenSchedule::Worker::Batch;

# This method will run once at server start
sub startup {
	my $self = shift;
	
	# Initialize router
	my $r = $self->routes;
	
	# Set namespace
	$r->namespace('OdenSchedule::Controller');
	
	# Reading configuration
	my $conf = $self->plugin('Config',{file => 'config/config.conf'});
	
	# Set cookie secret
	$self->secret('odenschedule'.$conf->{secret});
	
	# Reverse proxy support
	$ENV{MOJO_REVERSE_PROXY} = 1;
	$self->hook('before_dispatch' => sub {
		my $self = shift;
		if ( $self->req->headers->header('X-Forwarded-Host') && defined($conf->{base_path})) {
			# Set url base-path (directory path)
			my @basepaths = split(/\//,$self->config->{base_path});	shift @basepaths;
			foreach my $part(@basepaths){
				if($part eq ${$self->req->url->path->parts}[0]){ push @{$self->req->url->base->path->parts}, shift @{$self->req->url->path->parts};	
				} else { last; }
			}
		}
	});
	
	# Prepare database
	my $mongoDB = Data::Model::Driver::MongoDB->new( 
		host => 'localhost',
		port => 27017,
		db => 'odenschedule',
	);
	my $schema = OdenSchedule::DBSchema->new;
	$schema->set_base_driver($mongoDB);
	
	# Set database helper
	$self->attr(db => sub { return $schema; });
	$self->helper('db' => sub { shift->app->db });
	
	# Set database models
	$self->helper('getUserObj' => sub {
		my ($self, %hash) = @_;
		return OdenSchedule::Model::User->new( \($self->app->db), \($self->app->log), \%hash );
	});
	$self->helper('getScheduleObj' => sub {
		my ($self, %hash) = @_;
		return OdenSchedule::Model::Schedule->new( \($self->app->db), \($self->app->log), \%hash );
	});
	
	# Set timer for batch process
	Mojo::IOLoop->recurring(60 => sub {	return OdenSchedule::Worker::Batch->new(\($self->app),\($self->app->db)); });
	Mojo::IOLoop->singleton->reactor->on(error => sub { my ($reactor, $err) = @_; $self->app->log->error($err); });
	
	# Set user object helper
	$self->helper('ownUserId' => sub { return undef });
	$self->helper('ownUser' => sub { return undef });
	$self->stash(logined => 0);
	
	# Set log helper
	$self->helper('log' => sub { shift->app-> log });
	
	# Bridge (for auth)
	$r = $r->bridge->to('bridge#login_check');
	
	# Routes (for auth)
	$r->route('/session/oauth_google_redirect')->to('session#oauth_google_redirect',);
	$r->route('/session/oauth_google_callback')->to('session#oauth_google_callback',);
	
	# Routes
	$r->route('')->to('top#top_guest',);
	$r->route('/top')->to('top#top_user',);
	$r->route('/updater/oecu_schedule')->to('updater#oecu_schedule',);
	$r->route('/updater/calendar')->to('updater#calendar',);
	$r->route('/docs/about')->to('docs#about',);
	$r->route('/docs/agreement')->to('docs#agreement',);
	$r->route('/session/login')->to('session#login');
	$r->route('/session/logout')->to('session#logout');
}

1;
