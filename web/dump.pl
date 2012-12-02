#!/usr/bin/perl
#Copyright (c) 2012 Genome Research Ltd. 
#Author: Sam Nicholls <sn8@sanger.ac.uk>
#Author: Martin Pollard <mp15@sanger.ac.uk>
#
#This file is part of IYG Web.
#
#IYG Web is free software: you can redistribute it and/or modify it under 
#the terms of the GNU Affero General Public License as published by the Free 
#Software Foundation; either version 3 of the License, or (at your option) any 
#later version. 
#
#This program is distributed in the hope that it will be useful, but WITHOUT 
#ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more 
#details.
#
#You should have received a copy of the GNU Affero General Public License along
#with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

# Start Application
use IYG::App;
my $conf_path = $ENV{"IYG_CONF_PATH"};
my $app = IYG::App->new(conf_path => $conf_path);

my $barcode_flag;
my $barcode_or_publicid;

# Get either the decrypted barcode, or "public id" of the current user
if(defined($app->page->cgi->param('barcode'))){
    $barcode_flag = 1;
    $barcode_or_publicid = $app->decryptBarcode($app->page->cgi->param('barcode'))->decrypt();
}
elsif(defined($app->page->cgi->param('profile'))){
    $barcode_flag = 0;
    $barcode_or_publicid = $app->page->cgi->param('profile');
}

# Ensure a barcode was submitted, if not; error out.
if(!$barcode_or_publicid){
    print "not logged in";
}
else{
    # Get all variants for which the barcode has a result.
    my $traitResultSet = $app->dbh->query_all_snps_with_results({
        is_barcode => $barcode_flag,
        barcode_or_publicid => $barcode_or_publicid,
    });

    my @traitList;
    print "Content-Type: text/tab-separated-values\n";
    while(my $trait = $traitResultSet->fetchrow_hashref()){
        # Used by the template to uniquely name the "trait box" divs
        my $rs_id = $trait->{'rs_id'};
        my $genotype = $trait->{'genotype'};

        print "$rs_id\t$genotype\n";
    }
    $traitResultSet->finish;
    $app->dbh->disconnectDb();
}

exit;
__END__

=head1 NAME

traits.pl: Display a list of traits and their results for a particular user.

=head1 ADDRESS

_HOST_/traits

=head1 PURPOSE

For either a valid decrypted barcode, or valid public_id (a hashed and salted
version of the barcode used to avoid passing either the bardcode or the
auto-incrementing primary key around the application), this script will load
and render all the traits for which this user has at least one SNP result for.

For each trait, a button will allow a user to view a breakdown of the SNP
calls that affect this trait.

=head1 EXPECTED INPUTS

The script expects the following POST variables:

=over

=item * [barcode|profile]

Either an encrypted barcode submission, or a public_id.
If neither key resolves to a user in the database, the user will be returned
to the login view and instructed to try again.

=back

=head1 TEMPLATE

/templates/traits_list.tmpl
