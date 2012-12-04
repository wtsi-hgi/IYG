#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use HTML::Entities;

my $buffer;

while ( my $line = <STDIN> ) {
    $buffer .= $line;
} 

my $doc = decode_json $buffer; 

print encode_entities(decode_entities($doc->{'data'}->{'html'}), '^\n\x20-\x25\x27-\x7e');

