use v5.38;
use strict;
use warnings;

package Neoinfra::Utils;
use Exporter 'import';
use Term::ANSIColor;
use Net::OpenSSH;

sub ex {
    my $cmd = shift @_;

    print color 'bold';
    print "\$ $cmd";
    print color 'reset';
    print "\n";

     system($cmd);
}

sub exout {
    my $cmd = shift @_;

    print color 'bold';
    print "\$ $cmd";
    print color 'reset';
    print "\n";

    my $out = `$cmd`;
    return $out;
}

sub sayb {
    my $msg = shift @_;

    print color 'bold';
    print $msg;
    print color 'reset';
    print "\n";
}

sub exssh {
    my $ssh = shift;
    my $cmd = shift;

    my $host = $ssh->get_host;
    my $user = $ssh->get_user;

    sayb "($user\@$host)\$ $cmd";

    $ssh->system($cmd) or die "remote command failed: " . $ssh->error;
}

our @EXPORT_OK = qw(ex sayb exssh exout);

1;

