package IYG::Page;
use Moose;

# Standard QW, Pretty HTML, HTML Templating.
use CGI qw(:standard);
use CGI::Pretty;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;

has prepath => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    default => ""
);

has template => (
    is => 'rw',
    isa => 'Str'
);

has params => (
    is => 'rw'
);

has cgi => (
    is => 'ro',
    default => sub {
        return new CGI;
    }
);

# Render a Template to HTML
sub render {
    my $self = shift;

    my $prepath = "";
    if($_[0]->{'prepath'}){
        $prepath = $_[0]->{'prepath'};
    }

    my $t = HTML::Template->new(
        filename => $prepath."templates/".$_[0]->{'template'}.'.tmpl',
        die_on_bad_params => 0
    ); 
    $t->param($_[0]->{'params'});
    
    return "Content-Type: text/html\n\n", $t->output;
}

no Moose;
1;
__END__

=head1 NAME

Page - Builds an HTML page.

=head1 DESCRIPTION

Given a template name and hash of parameters, an HTML page
is generated and returned for display through use of CGI and Template::HTML.

=head1 ATTRIBUTES

=over

=item * prepath

Allows modification of the template path for scripts that are not in the root
folder (as HTML::Template seems to require an absolute path). For example,
the "handlers" inside /results require this prepath to be set manually to "../"
By default, the prepath is empty, so scripts in the root directory do not need
to provide this parameter.

=item * template

The name of the HTML template that will be used to build the page.
This needs only to be the name as the .tmpl extension and directory
path is appended to the parameter as necessary.
The template parameter is required on construction.

=item * params

A hash of key-value parameters that are to be passed to the page for display.
An example may be the page's title. Pages are rendered using HTML::Template
with variables displayed using the <TMPL_VAR> syntax.

=item * cgi

Wraps a CGI object to provide access to CGI parameters.

=back

=head1 METHODS

=over

=item * render

Generates and returns the HTML necessary to display the page contents with
an acceptable header. Note that this method DOES NOT actually display the page 
and it's return value should be printed in the calling script.

=back

=cut
