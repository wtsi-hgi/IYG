#!/usr/bin/env perl
use strict;
use warnings;

# Start App
use SOT::App;
my $app = SOT::App->new();

my $open_category = "";
if(defined($app->page->cgi->param('category'))){
    # start with this category open
    $open_category = $app->page->cgi->param('category');
}
my $open_category_num = 0;

my @category_list;
my $category_count = 0;
foreach my $category_name (sort {$a cmp $b} keys %{$app->data->data->{category}}) {
    $category_count++;
    
    my $category;
    $category->{'name'} = $category_name;
    $category->{'counter'} = $category_count;

    if($category_name eq $open_category) {
	$category->{'start_open'} = 1;
    }
    
    my @traits = sort {$a cmp $b} keys %{$app->data->data->{category}{$category_name}{trait}};
    foreach my $trait_name (@traits) {
	my @snp_ids = sort {$a cmp $b} keys %{$app->data->data->{trait}{$trait_name}{markername}};
	my @snps;
	foreach my $snp_id (@snp_ids) {
	    if($snp_id ne "") {
		push @snps, { 
		    snp_id => $snp_id,
		    trait_name => $trait_name,
		    short_name => $app->data->data->{trait}{$trait_name}{shortname},
		    category => $category_name,
		};
	    }
	}
	push @{$category->{'traits'}}, {
	    trait_name => $trait_name,
	    short_name => $app->data->data->{trait}{$trait_name}{shortname},
	    category => $category_name,
	    snps => \@snps,
	};
    }
    
    push (@category_list, $category);
}

# Load category listing template and pass results for display.
print $app->page->render({
    template => 'category_list',
    params => {
        TITLE => "Category List",
        RESULT => [@category_list],
	OPENCAT => $open_category_num,
    },
			 });


exit;
__END__

=head1 NAME

index.pl: Display a list of trait categories and link to pages for editing trait/SNP descriptions.

=head1 ADDRESS

_HOST_/[index]

=head1 PURPOSE


=head1 EXPECTED INPUTS


=head1 TEMPLATE

/templates/traits_list.tmpl
