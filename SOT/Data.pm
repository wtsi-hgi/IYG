package SOT::Data;

use Moose;

use SOT::Conf;

my $conf = SOT::Conf->new({
    conf_path => "/home/www-data/sot.conf",
			  });

has data => (
    is => 'ro',
    isa => 'HashRef',
    builder => '_build_data',
    lazy_build => 1,
    );

sub _build_data {
    my %data;

    my $trait_file = "/home/www-data/iyg-snps-traits.txt";
    my $traitfh;
    open($traitfh, "<$trait_file") or die "Could not open $trait_file\n";
    
    my $headline = <$traitfh>;
    chomp $headline; 
    my @headers = split /\t/, $headline, -1;
    my %header2col;
    my %col2header;
    for(my $i=0; $i<=$#headers; $i++) {
	$header2col{$headers[$i]} = $i;
	$col2header{$i} = $headers[$i];
	print STDERR "assiging col $i to header $headers[$i]\n";
    }
    
    die "could not find MarkerName column in header [@headers]" unless exists($header2col{MarkerName});
    die "could not find Category column in headers [@headers]" unless exists($header2col{Category});
    die "could not find Trait column in headers [@headers]" unless exists($header2col{Trait});
    die "could not find ShortName column in headers [@headers]" unless exists($header2col{ShortName});
    
    
    while(my $line = <$traitfh>) {
	chomp $line;
	my @data = split /\t/, $line, -1;
	my $markername = $data[$header2col{MarkerName}];
	my $category = $data[$header2col{Category}];
	my $trait = $data[$header2col{Trait}];
	my $shortname = $data[$header2col{ShortName}];
	
	$data{markername}{$markername}{trait}{$trait} = 1;
	$data{trait}{$trait}{markername}{$markername} = 1;
	
	$data{markername}{$markername}{category}{$category} = 1;
	$data{category}{$category}{markername}{$markername} = 1;
	
	$data{category}{$category}{trait}{$trait} = 1;
	
	if(exists($data{trait}{$trait}{category})) {
	    die "mismatch trait $trait category $category: ".$data{trait}{$trait}{category}."\n" unless $data{trait}{$trait}{category} eq $category;
	} else {
	    $data{trait}{$trait}{category} = $category;
	}
	if(exists($data{shortname}{$shortname}{trait})) {
	    die "mismatch shortname $shortname trait $trait: ".$data{shortname}{$shortname}{trait}."\n" unless $data{shortname}{$shortname}{trait} eq $trait;
	} else {
	    $data{shortname}{$shortname}{trait} = $trait;
	}
	if(exists($data{trait}{$trait}{shortname})) {
	    die "mismatch trait $trait shortname $shortname: ".$data{trait}{$trait}{shortname}."\n" unless $data{trait}{$trait}{shortname} eq $shortname;
	} else {
	    $data{trait}{$trait}{shortname} = $shortname;
	}
    }
    close $traitfh;

    return \%data;
}


no Moose;
1;
__END__

