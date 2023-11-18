use v5.38;
use strict;
use warnings;

package Neoinfra::Command::ocilogin;
use Neoinfra -command;
use Neoinfra::Utils qw(ex);

use Data::Dumper;


sub abstract { "login to oci with the correct options" }


sub execute {
    ex "oci session authenticate --region eu-marseille-1 --profile-name DEFAULT";
}

1;