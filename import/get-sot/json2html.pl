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
my $decoded_doc = decode_entities($doc->{'data'}->{'html'});

$decoded_doc =~ s/\[\[[^\]]+\<a\ href=\"([^\"]+)\"[^\]]*\]\[([^\]]+)\]\]/\<a\ href=\"$1\"\>$2\<\/a\>/g;

print encode_entities($decoded_doc, '^\n\x20-\x25\x27-\x7e');

