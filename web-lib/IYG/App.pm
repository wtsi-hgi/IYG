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

package IYG::App;

use Moose;

use IYG::Conf;
use IYG::Db;
use IYG::Decrypt;
use IYG::Page;

sub _build_conf { 
    my $self = shift;
    IYG::Conf->new({
      conf_path => $self->conf_path(),
    }); 
}

has conf => (
    is => 'ro',
    lazy => 1,
    builder => '_build_conf',
);

has conf_path => (
    is => 'ro',
    required => 1,
);

has page => (
    is => 'ro',
    lazy => 1,
    builder => '_build_page',
);

sub _build_page {
    my $self = shift;
    my $conf = $self->conf();
    return IYG::Page->new({
	prepath => $conf->getDocRoot(),
    });
}


has dbh => (
    is => 'ro',
    lazy => 1,
    builder => '_build_dbh',
);

sub _build_dbh {
    my $self = shift;
    return IYG::Db->new({
	db_host => $self->conf->getCredential("db_host"),
	db_port => $self->conf->getCredential("db_port"),
	db_name => $self->conf->getCredential("db_name"),
	db_user => $self->conf->getCredential("db_user"),
	db_pass => $self->conf->getCredential("db_pass")
    });
}

sub getDb{
    my $self = shift;
    return $self->dbh->getDbh();
}

sub decryptBarcode{
    my $self = shift;
    return IYG::Decrypt->new({
        secret => $self->conf->getCredential("decrypt_key"),
        message => $_[0],
	secring => $self->conf->getCredential("decrypt_secring"),
    });
}

no Moose;
1;
__END__

=head1 NAME

App - IYG Application Wrapper

=head1 DESCRIPTION

Encapsulates the database connection and provides access to the 
Barcode Decryption mechanism.

=head1 ATTRIBUTES

=over

=item * page

Holds an IYG::Page object to allow scripts to access the page renderer and
any CGI variables.

=item * dbh

Connects to the IYG database on construction and holds an IYG::Db database 
wrapper, allowing scripts to access various stored queries inside the class.

=back

=head1 METHODS

=over

=item * getDb

Returns the database handler for the execution of queries.

=item * decryptBarcode

Returns a decrypted barcode given the secret key passphrase and encrypted
PGP message.

=back

=cut
