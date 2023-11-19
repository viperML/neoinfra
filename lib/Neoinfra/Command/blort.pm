package Neoinfra::Command::blort;
use v5.38;
use strict;
use warnings;
use Neoinfra -command;

sub abstract { "blortex algorithm" }

sub description { "Long description on blortex algorithm" }

sub opt_spec {
  return (
    [ "blortex|X",  "use the blortex algorithm" ],
    [ "recheck|r",  "recheck all results"       ],
  );
}

sub validate_args {
  my ($self, $opt, $args) = @_;

  # no args allowed but options!
  $self->usage_error("No args allowed") if @$args;
}

sub execute {
  my ($self, $opt, $args) = @_;

  my $result = $opt->{blortex} ? blortex() : blort();

  recheck($result) if $opt->{recheck};

  print $result;
}

1;