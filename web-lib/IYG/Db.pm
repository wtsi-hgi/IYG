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

package IYG::Db;

use Moose;
use DBI;

has db_host => (
    is => 'ro',
);

has db_port => (
    is => 'ro',
);

has db_name => (
    is => 'ro',
);

has db_user => (
    is => 'ro',
);

has db_pass => (
    is => 'ro',
);

has dbh => (
    is => 'ro',
    default => sub {
    my $self = shift;
        return $self->connectDb();
    }
);

sub getDbh{
    my $self = shift;
    return $self->dbh;
}

sub connectDb{
    my $self = shift;
    my $dbh = DBI->connect(
        "DBI:mysql:".$self->db_name.":".$self->db_host.":".$self->db_port,
        $self->db_user,
        $self->db_pass,
    ) or die('Database Connection Failed.');
    return $dbh;
}

sub disconnectDb{
    my $self = shift;
    $self->dbh->disconnect();
}

sub query_trait{
    my $self = shift;
    my $query = q(
        SELECT traits.name AS trait_name, traits.description AS trait_description, traits.short_name AS trait_short_name
        FROM traits
        WHERE traits.trait_id = ?;
      );                                                                               
    my $traitResultQuery = $self->dbh->prepare($query);
    $traitResultQuery->execute( $_[0]->{'trait'} );
    return $traitResultQuery;
}

sub query_all_genotypes_for_variant{
    my $self = shift;
    my $query = q(
        SELECT variants.variant_id, variants.genotype,
        variants_traits.description, ROUND(variants.popfreq, 2) AS population_freq
        FROM variants
        JOIN variants_traits ON variants.variant_id = variants_traits.variant_id
        WHERE variants_traits.trait_id = ?
        AND variants.snp_id = ?;
      );                                                                           
    my $variantsQuery = $self->dbh->prepare($query); 
    $variantsQuery->execute( $_[0]->{'trait'}, $_[0]->{'snp'} );
    return $variantsQuery;
}

sub query_all_snp_results_for_trait{
    my $self = shift;
    my $query = q(
      SELECT results.variant_id, snps.snp_id, snps.rs_id, snps_traits.description
      FROM profiles
      JOIN results ON profiles.profile_id = results.profile_id
      JOIN variants ON results.variant_id = variants.variant_id
      JOIN snps ON variants.snp_id = snps.snp_id
      JOIN variants_traits ON variants.variant_id = variants_traits.variant_id
      JOIN traits ON variants_traits.trait_id = traits.trait_id
      JOIN snps_traits ON variants.snp_id = snps_traits.snp_id AND traits.trait_id = snps_traits.trait_id
      AND traits.trait_id = ?
      WHERE profiles.public_id = ?
      AND profiles.consent_flag = 1
      AND traits.active_flag = 1;
    );                                                                                 
    my $snpResultQuery = $self->dbh->prepare($query);
    $snpResultQuery->execute( $_[0]->{'trait'}, $_[0]->{'profile'} );
    return $snpResultQuery;
}

sub query_all_traits_with_results{
    my $self = shift;
    my $qtype = "";
    if($_[0]->{'is_barcode'} == 1){
        $qtype = "WHERE profiles.barcode = ?";
    }
    else{ #Else assume it's a "public id"
        $qtype = "WHERE profiles.public_id = ?";
    }

    my $query = "
        SELECT COUNT(*) as snp_count, ROUND(AVG(results.confidence),2) as trait_conf,
        profiles.profile_id, profiles.public_id, traits.trait_id,snps.snp_id, 
        variants.variant_id, traits.name, variants_traits.value, traits.handler,
        traits.predictability
        FROM profiles
        JOIN results ON results.profile_id = profiles.profile_id
        JOIN variants ON results.variant_id = variants.variant_id
        JOIN snps ON variants.snp_id = snps.snp_id
        JOIN variants_traits ON variants.variant_id = variants_traits.variant_id
        JOIN traits ON variants_traits.trait_id = traits.trait_id ".$qtype." 
        AND profiles.consent_flag = 1
        AND traits.active_flag = 1
        GROUP BY traits.trait_id
      ";
    my $barcode_or_publicid = $_[0]->{'barcode_or_publicid'};
    print STDERR "query_all_traits_with_results: query=[$query] value=[$barcode_or_publicid]\n";
    my $traitResultQuery = $self->dbh->prepare($query);
    $traitResultQuery->execute( $barcode_or_publicid );
    return $traitResultQuery;
}

sub query_all_snps_with_results{
    my $self = shift;

    my $query = "
        SELECT snps.rs_id, variants.genotype
        FROM profiles
        JOIN results ON results.profile_id = profiles.profile_id
        JOIN variants ON results.variant_id = variants.variant_id
        JOIN snps ON variants.snp_id = snps.snp_id
        WHERE profiles.public_id = ?
        AND profiles.consent_flag = 1
      ";
    my $profile = $_[0]->{'profile'};
    print STDERR "query_all_snps_with_results: query=[$query] value=[$profile]\n";
    my $snpResultQuery = $self->dbh->prepare($query);
    $snpResultQuery->execute( $profile );
    return $snpResultQuery;
}

sub barcodeToProfile{
    my $self = shift;
    my $query = "SELECT public_id FROM profiles WHERE profiles.barcode = ?";

    my $profileResultSet = $self->dbh->prepare($query);
    $profileResultSet->execute( $_[0] );

    if($profileResultSet->rows > 0){
        my $profile = $profileResultSet->fetchrow_hashref();
        return $profile->{'public_id'};
    } else{
        return undef;
    }
}

no Moose;
1;
__END__

=head1 NAME

Db - Database Handler Wrapper

=head1 DESCRIPTION

Facilitates connection to the IYG database and wraps a DBI connection handler.

=head1 ATTRIBUTES

=over

=item * db_host

Database Host (usually localhost or 127.0.0.1)
If you are unable to connect to the database via a socket, try connecting over
TCP/IP by providing '127.0.0.1' instead of 'localhost'.

=item * db_port

Database Connection Port (usually unspecified or 3380)

=item * db_name

Database Name

=item * db_user

Database User

=item * db_pass

Database Password

=item * dbh

The connected DBI object.

=back

=head1 METHODS

=over

=item * getDbh

Returns the connected DBI object. Not advised as this breaks the encapsulation
that this wrapper provides, but will allow scripts to use the DBI object
directly if wanted.

=item * connectDb

Connects to the database with the given credentials and returns the 
L<DBI> database handler for the execution of queries.

=item * disconnectDb

Explicitly disconnect the database handler from the database following the
execution of all desired queries.

=item * query_trait

Execute query and return the result set for a given trait id.
Primarily used when loading the results of a particular trait to populate
the template's name and description fields.

=item * query_all_genotypes_for_variant

Execute query and return the result set of all genotype variants for a
particular SNP and trait. This populates the table of genotypes for the
trait result template, showing the different genotypes and offering - if
available - contextual descriptions on how this genotype has an effect on
the trait in question.

=item * query_all_snp_results_for_trait

Execute query and return the result set of all SNPs that cause have an effect
on a particular trait, if the user profile has a result for that SNP.
Populates the "SNP boxes" on the trait results pages.

=item * query_all_traits_with_results

Execute query and return the result set for all traits that this user has at
least one SNP result for. This populates the main "trait list" page the user
can view after a successful login.

=back

=cut
