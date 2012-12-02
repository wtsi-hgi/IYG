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
my $app = IYG::App->new();

# Ensure a profile_id was received, or load login template.
if(!defined($app->page->cgi->param('profile'))){
    print $app->page->render({
        template => 'login',
        prepath => "../",
        params => {
            TITLE => 'Login',
        },
    });
}
else{
    # Get the SNPs this profile_id has results for that relate to this trait.
    my $snpResultSet = $app->dbh->query_all_snp_results_for_trait({
        trait => $app->page->cgi->param('trait'),
        profile => $app->page->cgi->param('profile')
    });

    # Get some information on the selected trait
    my $traitResultSet = $app->dbh->query_trait({
        trait => $app->page->cgi->param('trait')
    });

    my $variantGenotypeResultSet; # Placeholder for use in loop

    # Ensure at least one SNP and one trait is returned.
    if($snpResultSet->rows > 0 && $traitResultSet->rows == 1){
        my $traitResult = $traitResultSet->fetchrow_hashref();
        my @snps;
        my $count = 1;

        while(my $snp = $snpResultSet->fetchrow_hashref()){

            # Get all the possible genotype variants for this SNP for display.
            # Descriptions for the outcome of each genotype result will be given
            # in the context of the selected trait.
            $variantGenotypeResultSet = $app->dbh->query_all_genotypes_for_variant({
                trait => $app->page->cgi->param('trait'),
                snp => $snp->{'snp_id'}
            });
      
            # Ensure SNPs with at least one genotypic variant are displayed.
            # (Although really there should only ever be 3)
            if($variantGenotypeResultSet->rows > 0){
                my @variants;
                while(my $variant = $variantGenotypeResultSet->fetchrow_hashref()){
                    if($variant->{'variant_id'} == $snp->{'variant_id'}){
                        $variant->{'isresult'} = 1;
                        $snp->{'percent'} = $variant->{'population_freq'}; # Simple access to % for template.
                        $snp->{'count'} = $count;
                    }
                    push(@variants, $variant);
                }
                $snp->{'variants'} = [@variants];
                push(@snps, $snp);
                $count += 1;
            }
        }

        # Load the variant info template and pass the parameters for display.
        print $app->page->render({
            prepath => "../",
            template => "results/default",
            params => {
                TITLE => "View Trait",
                TRAIT_NAME => $traitResult->{'trait_name'},
                TRAIT_DESCRIPTION => $traitResult->{'trait_description'},
                SNPS => [@snps],
                PROFILE_ID => $app->page->cgi->param('profile'),
            },
        });
    }
    else{
        #TODO Should probably return user to trait page instead?
        print $app->page->render({
            prepath => "../",
            template => 'login',
            params => {
                TITLE => 'Login',
            },
        });
    }

    $snpResultSet->finish;
    $variantGenotypeResultSet->finish;
    $traitResultSet->finish;
    $app->dbh->disconnectDb();
}

exit;
__END__

=head1 NAME

results/index.pl: Default trait results "handler"

=head1 ADDRESS

_HOST_/results/[index]

=head1 PURPOSE

Loads all data pertaining to SNPs that have an effect on this trait and
renders them with the default trait results template; displaying the trait
name and description and a "SNP box" for each SNP detailing the possible
genotypes and frequenies, and a "population bar" showing the user's frequency
compared to the rest of the sample.

=head1 EXPECTED INPUTS

The script expects the following POST variables:

=over

=item * profile

The public_id of the current user. Failure to provide this will cause the script
to load the login template.

=item * trait

The trait_id for the trait to be viewed.

=back

=head1 TEMPLATE

/templates/results/default.tmpl
