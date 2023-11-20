use v5.38;
use strict;
use warnings;

use JSON;
use HTTP::Tiny;
use Data::Dumper;

my $key  = $ENV{KEY};
my $addr = $ENV{VAULT_ADDR};

my $url          = "$addr/v1/sys/unseal";
my $data         = { key => $key };
my $data_encoded = encode_json($data);
print Dumper $data_encoded;

my $http     = HTTP::Tiny->new();
my $response = $http->post(
    $url,
    {
        headers => { 'Content-Type' => 'application/json' },
        content => $data_encoded
    }
);

print Dumper $response;

die "Failed!\n" unless $response->{success};
