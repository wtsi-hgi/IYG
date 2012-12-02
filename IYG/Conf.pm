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

package IYG::Conf;

use Moose;

has conf_path => (
    is => 'ro',
    required => 1,
);

has credentials => (
    is => 'ro',
    default => sub {
        my $self = shift;
        my %creds;
        open FILE, $self->conf_path or die $!;

        while(<FILE>){
            chomp;
            my ($key, $val) = split(/=/); #Split key-value pairs by '='
            if (/^[#]/){ # Ignore comments
                next;
            }
            $creds{$key} .= exists $creds{$key} ? $val : next;
        }
        return \%creds;
    }
);

sub getCredential{
    my $self = shift;
    return $self->credentials->{$_[0]};
}

sub getDocRoot{
    my $self = shift;
    if(exists($self->credentials->{"iyg_documentroot"})) {
	return $self->credentials->{"iyg_documentroot"};
    } else {
	return "";
    }
}

no Moose;
1;
__END__

=head1 NAME

Conf - IYG Application Configuration Handler

=head1 DESCRIPTION

Reads each line of the specified key-value configuration file into a hash 
and provides a method to access the credentials hash by key.

=head1 ATTRIBUTES

=over

=item * conf_path

Path to the configuration file, each key-value pair must be on its own line
in the format "key=value". Comments must be preceded by '#' at the beginning
of the line.

=item * credentials

Hash containing key-value pairs representing configuration options.
Note that no sanity checking is performed upon the configuration file, for
example no warning will be issued for keys that are required for the
application to function being missing.

=back

=head3 METHODS

=over

=item * getCredential

Query the credentials hash for a given key and returns the value if found.
Non-existent values return empty.

=back

=cut
