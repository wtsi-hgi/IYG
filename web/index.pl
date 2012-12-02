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

# Render and Load Login
print $app->page->render({
    template => 'login',
    params => {
        TITLE => "Login"
    },
});

$app->dbh->disconnectDb();

exit;
__END__

=head1 NAME

IYG Barcode Login

=head1 ADDRESS

_HOST_/[index]

=head1 PURPOSE

Constructs an L<IYG::Page|IYG::Page> which prompts user to enter a barcode 
to access the Inside Your Genome trait results list.
The barcode is encrypted with PGP and submitted via a POST form in the login 
template to the traits.pl script.

=head1 EXPECTED INPUTS

None.

=head1 TEMPLATE

templates/login.tmpl
