package OdenSchedule::Controller::Docs;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub about {
  my $self = shift;
  $self->render();
}

sub agreement {
  my $self = shift;
  $self->render();
}

1;
