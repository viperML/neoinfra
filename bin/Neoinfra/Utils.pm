use v5.38;
use strict;
use warnings;

package Neoinfra::Utils;
use Exporter 'import';
use Term::ANSIColor;

sub ex {
    my $cmd = shift @_;

    print color 'bold';
    print $cmd;
    print color 'reset';
    print "\n";

    system($cmd);
}

our @EXPORT_OK = qw(ex);

1;

