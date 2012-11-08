package OdenSchedule::Controller::Top;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub top {
  my $self = shift;

  $self->render();
}

1;
