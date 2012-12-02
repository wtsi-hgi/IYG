#!/usr/bin/perl
#Copyright (c) 2012 Genome Research Ltd. 
#Author: Sam Nicholls <sn8@sanger.ac.uk>
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

# Ensure a barcode was submitted, if not; load login template.
if(!$barcode_or_publicid){
    print $app->page->render({
        template => 'login',
        params => {
            TITLE => "Login",
        },
    });
}
else{
    # Get all Traits for which the barcode has a result.
    my $traitResultSet = $app->dbh->query_all_traits_with_results({
        is_barcode => $barcode_flag,
        barcode_or_publicid => $barcode_or_publicid,
    });

    my @traitList;
    if($traitResultSet->rows > 0){
        my $count = 1;
        while(my $trait = $traitResultSet->fetchrow_hashref()){
            # Used by the template to uniquely name the "trait box" divs
            $trait->{'counter'} = $count;

            # Awful way to pass how many stars to print to the template
            if($trait->{'predictability'} >= 3){
                $trait->{'predictability3'} = 1;
            }
            elsif($trait->{'predictability'} == 2){
                $trait->{'predictability2'} = 1;
            }
            elsif($trait->{'predictability'} == 1){
                $trait->{'predictability1'} = 1;
            }
            else{
                $trait->{'predictability0'} = 1;
            }

            # Path which will handle the result page for this trait
            if(!$trait->{'handler'}){
                $trait->{'handler'} = "results/";
            }
            else{
                my $handler = "results/".$trait->{'handler'};
                $trait->{'handler'} = $handler;
            }

            # Mark any traits for which more than one SNP site has an effect
            # Triggers a message in the trait list template informing users 
            # the trait is a composite of multiple SNPs
            if($trait->{'snp_count'} > 1){
                $trait->{'multi_snp'} = 1;
            }

            push (@traitList, $trait);
            $count++;
        }

        # Load trait listing template and pass results to the renderer for display
        print $app->page->render({
            template => 'trait_list',
            params => {
                TITLE => "View Trait List",
                RESULT => [@traitList],
            },
        });
    }
    else{
        # If no results were returned, the barcode wasn't in the db. Load login template
        print $app->page->render({
            template => 'login',
            params => {
                TITLE => "Login",
                MESSAGE => "<div class='alert alert-error'><a class='close' data-dismiss='alert', href='#'>x</a>Invalid Barcode! Please try again.</div>"
            },
        });
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
