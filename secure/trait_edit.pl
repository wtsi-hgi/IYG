#!/usr/bin/env perl
use strict;
use warnings;

# Start App
use SOT::App;
my $app = SOT::App->new();

my $short_name = "";
if(defined($app->page->cgi->param('trait'))){
    $short_name = $app->page->cgi->param('trait');
} elsif($app->page->cgi->path_info ne "") {
    my @path_components = split /\//, $app->page->cgi->path_info;
    $short_name = $path_components[1];
}
if($short_name eq "") {
    $app->error("trait not specified");
}

my $trait_name = $app->data->data->{shortname}{$short_name}{trait} || "";
if($trait_name eq "") {
    $app->error("full trait name not found for $short_name");
}

my $category_name = $app->data->data->{trait}{$trait_name}{category} || "";
if($category_name eq "") {
    $app->error("category name not found for $trait_name");
}

my @snp_ids = sort {$a cmp $b} keys %{$app->data->data->{trait}{$trait_name}{markername}};
my @snps;
foreach my $snp_id (@snp_ids) {
    if($snp_id ne "") {
	my $snp_id_nors = $snp_id;
	$snp_id_nors =~ s/^rs//;
	push @snps, { 
	    snp_id => $snp_id,
	    snp_id_nors => $snp_id_nors,
	    trait_name => $trait_name,
	    short_name => $app->data->data->{trait}{$trait_name}{shortname},
	    category => $category_name,
	};
    }
}

my $trait = {
    trait_name => $trait_name,
    short_name => $short_name,
    category => $category_name,
    snps => \@snps,
};
    
my @traits;
push @traits, $trait;

# Load category listing template and pass results for display.
print $app->page->render({
    template => 'edit_traits',
    params => {
        TITLE => "Edit Trait - $trait_name",
        TRAITS => [@traits],
    },
			 });


exit;
__END__

=head1 NAME

trait_edit.pl: Edit a particular trait.

=head1 ADDRESS

_HOST_/[index]

=head1 PURPOSE


=head1 EXPECTED INPUTS


=head1 TEMPLATE

/templates/traits_list.tmpl
