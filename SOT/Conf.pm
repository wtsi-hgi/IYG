package SOT::Conf;

use Moose;

has conf_path => (
  is => 'ro',
);

has credentials => (
  is => 'ro',
  'default' => sub {
    my $self = shift;
    my %creds;
    open FILE, $self->conf_path or die $!;
    while(<FILE>){
        chomp;
        my ($key, $val) = split(/=/);
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

no Moose;
1;
__END__

=head1 NAME

Conf - SOT Application Configuration Handler

=head1 DESCRIPTION

Reads each line of the specified key-value configuration file into a hash 
and provides a method to access the credentials hash by key.

=head1 ATTRIBUTES

=over 4

=item *

=head3 conf_path

Path to the configuration file, each key-value pair must be on its own line
in the format "key=value". Comments must be preceded by '#' at the beginning
of the line.

=head3 credentials

Hash containing key-value pairs representing configuration options.
Note that no sanity checking is performed upon the configuration file, for
example no warning will be issued for keys that are required for the
application to function being missing.

=back

=head3 METHODS

=over 4

=item *

=head3 getCredential

Query the credentials hash for a given key and returns the value if found.
Non-existent values return empty.

=back

=cut
