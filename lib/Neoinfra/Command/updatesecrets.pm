package Neoinfra::Command::updatesecrets;
use v5.38;
use strict;
use warnings;
use Neoinfra -command;
use Neoinfra::Utils qw(ex sayb exssh exout);

use Exporter 'import';
use File::Spec::Functions qw(catdir);

sub abstract { "update all secrets" }

sub opt_spec {
  return (
  );
}

sub execute {
  my $root = $ENV{ROOT};
  chdir catdir($root);

  my @files = glob("secrets/*.yaml");
  for my $file (@files) {
    sayb "updating $file";
    ex "sops updatekeys $file --yes";
  }
}

# our @EXPORT_OK = qw(ex sayb exssh exout);

1;