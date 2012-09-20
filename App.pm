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

my $conf = IYG::Conf->new({
    conf_path => "/path/to/iyg.conf"}); #TODO Path to iyg.conf

has page => (
    is => 'ro',
    default => sub {
        return IYG::Page->new();
    }
);

has dbh => (
    is => 'ro',
    default => sub {
        return IYG::Db->new({
            db_host => $conf->getCredential("db_host"),
            db_port => $conf->getCredential("db_port"),
            db_name => $conf->getCredential("db_name"),
            db_user => $conf->getCredential("db_user"),
            db_pass => $conf->getCredential("db_pass")
        });
    }
);

sub getDb{
    my $self = shift;
    return $self->dbh->getDbh();
}

sub decryptBarcode{
    my $self = shift;
    return IYG::Decrypt->new({
        secret => $conf->getCredential("decrypt_key"),
        message => $_[0]
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

=over 4

=item *

=head3 page

Holds an IYG::Page object to allow scripts to access the page renderer and
any CGI variables.

=head3 dbh

Connects to the IYG database on construction and holds an IYG::Db database 
wrapper, allowing scripts to access various stored queries inside the class.

=back

=head1 METHODS

=over 4

=item *

=head3 getDb

Returns the database handler for the execution of queries.

=head3 decryptBarcode

Returns a decrypted barcode given the secret key passphrase and encrypted
PGP message.

=back

=cut
