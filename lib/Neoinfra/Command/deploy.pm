package Neoinfra::Command::deploy;
use v5.38;
use strict;
use warnings;
use Neoinfra -command;
use Neoinfra::Utils qw(ex sayb exssh exout);

use Data::Dumper;
use JSON;
use Net::OpenSSH;
use String::Util qw(trim);
use File::Spec::Functions qw(catdir);

sub abstract { "deploy NixOS configuration" }

sub opt_spec {
  return (
    [ "server|s=s",  "hostname to deploy", { required => 1  } ],
  );
}

sub execute {
  my $root = $ENV{ROOT};
  chdir catdir($root, "terraform");

  my ($self, $opt, $args) = @_;

  my $server = $opt->server;

  my $tfOutput = `terraform output -json`;
  my $tfOutputsJson = decode_json($tfOutput);

  # get the $hostname_ip from terraform output
  my $host = $tfOutputsJson->{"$server\_ip"}->{"value"};
  $host = "root\@$host";

  ex "ssh-add ./id";

  sayb "Deploying to $server ($host)";

  InstallNix($host);


  my $derivation = exout "nix build $root#nixosConfigurations.$server.config.system.build.toplevel --no-link --print-out-paths";
  trim $derivation;
  chomp $derivation;

  ex "nix copy --to ssh://$host --substitute-on-destination $derivation";

  my $ssh = Net::OpenSSH->new($host);
  $ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;


  exssh $ssh, "nix build --profile /nix/var/nix/profiles/system --no-link $derivation";

  exssh $ssh, "/nix/var/nix/profiles/system/etc/format";
  exssh $ssh, "touch /etc/NIXOS";
  exssh $ssh, "env NIXOS_INSTALL_BOOTLOADER=1 /nix/var/nix/profiles/system/bin/switch-to-configuration boot";
}

sub InstallNix {
  my $host = shift;

  my $ssh = Net::OpenSSH->new($host);
  $ssh->error and die "Couldn't establish SSH connection: ". $ssh->error;

  exssh $ssh, "curl --proto '=https' --tlsv1.2 -sSf -o nix-installer -L https://install.determinate.systems/nix/tag/v0.14.0";
  exssh $ssh, "sh ./nix-installer install --no-confirm";
}

1;