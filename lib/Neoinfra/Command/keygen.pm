package Neoinfra::Command::keygen;
use v5.38;
use strict;
use warnings;

use Neoinfra -command;
use Neoinfra::Utils qw(ex sayb exssh exout);
use FindBin;
use File::Spec::Functions qw(catdir);

use Data::Dumper;
use JSON;
use Net::OpenSSH;
use String::Util qw(trim);
use File::Slurp;

sub abstract { "regenerate host keys" }

sub opt_spec {
  return (
    [ "host|H=s",  "hostname generate keys for", { required => 1  } ],
  );
}

sub execute {
  my $root = $ENV{ROOT};
  chdir catdir($root);

  my ($self, $opt, $args) = @_;
  my $host = $opt->host;


  # remove previous key
  sayb "removing previous key";
  unlink "secrets/$host.age";

  ex "age-keygen -o secrets/$host.age";


  my $pubkey = exout "age-keygen -y secrets/$host.age";
  chomp $pubkey;
  trim $pubkey;
  write_file("secrets/$host.age.pub", $pubkey);

  my $sopsfile = read_file(".sops.yaml");

  # find the host &anchor and replace the value of the age key. If not, add it as a new key
  # keys:
  #   - &host1 agekey1
  #   - &host2 agekey2

  if ($sopsfile =~ /- &\Q$host\E\s*([^#]*)/) {
    sayb "updating public key";
    my $regex = qr{&$host\s+(\S+)};
    $sopsfile =~ s{$regex}{&$host $pubkey}g;
  } else {
    sayb "adding public key";
    $sopsfile =~ s/keys:\s*\n/keys:\n  - \&$host $pubkey\n/g;
  }

  write_file(".sops.yaml", $sopsfile);

  # run $ sops updatekeys $s for every file with secrets

  my @files = glob("secrets/*.yaml");
  for my $file (@files) {
    sayb "updating $file";
    ex "sops updatekeys $file --yes";
  }
}

1;