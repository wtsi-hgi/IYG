package SOT::App;

use Moose;

use SOT::Conf;
use SOT::Page;
use SOT::Data;

my $conf = SOT::Conf->new({
    conf_path => "/home/www-data/sot.conf"});

has page => (
  is => 'ro',
  default => sub {
    return SOT::Page->new();
  }
);

has data => (
  is => 'ro',
  default => sub {
    return SOT::Data->new();
  }
);

sub error {
    my $self = shift;
    my $err = shift;
    print $self->page->render({
	template => 'error',
	params => {
	    TITLE => "Error",
	    ERROR => $err,
	},
			     });
    exit 1;
}

no Moose;
1;
__END__

=head1 NAME

App - SOT Application Wrapper

=head1 DESCRIPTION


=head1 ATTRIBUTES

=over 4

=item *

=head3 page

Holds an SOT::Page object to allow scripts to access the page renderer and
any CGI variables.

=back

=head1 METHODS

=over 4

=item *

=back

=cut
