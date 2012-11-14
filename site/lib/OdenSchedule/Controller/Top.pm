package OdenSchedule::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

use utf8;

sub top_guest {
  my $self = shift;
  $self->render();
}

sub top_user {
  my $self = shift;
  $self->stash('isUser_google', 1);
  $self->render();
}

1;
