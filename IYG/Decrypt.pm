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

package IYG::Decrypt;

use Moose;
use Crypt::OpenPGP;

has secring => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has secret => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has message => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

sub decrypt{
    my $self = shift;

    # Decrypt
    my $pgp = Crypt::OpenPGP->new(
	Compat => "GnuPG",
	SecRing => $self->secring,
	);
    my($pt, $valid, $sig) = $pgp->decrypt(
        Data => $self->message,
        Passphrase => $self->secret,
    );
    die ("Sorry. Barcode decryption failed... ", $pgp->errstr) unless $pt;
    return $pt;
}

no Moose;
1;
__END__

=head1 NAME

Decrypt - PGP Message Decrypter

=head1 DESCRIPTION

Utilizes the Crypt::OpenPGP library to decrypt PGP encoded messages sent by
the barcode login script.

=head1 ATTRIBUTES

=over

=item * secret

The passphrase for the private key that forms a pair with the public key
used to encrypt the message.

=item * message

The PGP encoded message to be decrypted.

=back

=head1 METHODS

=over

=item * decrypt

Decrypt and return the result (in this context; a barcode)

=back

=cut
