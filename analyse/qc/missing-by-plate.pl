use strict;
my %miss;
my %tot;

my %ymarkers = (
	"rs2032597" => 1,
	"rs35284970" => 1,
	"rs2032658" => 1,
	"rs13447352" => 1,
	"rs9786184" => 1,
	"rs2032652" => 1,
	"rs2534636" => 1
	);

open (my $in, "<", "ALL_assay_summary.fakebarcode.tsv.txt");
<$in>; #header
while (<$in>){
	my @fields = split /\t|\n/;
	$tot{$fields[11]}{$fields[5]}++;
	if ($fields[10] eq "No Call"){
		$miss{$fields[11]}{$fields[5]}++;
	}
}
close $in;

foreach my $snp (keys %tot){
	print "$snp";
	if ($ymarkers{$snp}){
		print "*";
	}
	
	my $avg = 0;
	my $n = 0;
	foreach my $plate (keys %{$tot{$snp}}){
		my $rate = $miss{$snp}{$plate}/$tot{$snp}{$plate};
		printf "\t%.3f",$rate;
		$avg += $rate;
		$n++;
	}
	my $final = $avg/$n;
	printf "\t%.3f\n",$final;
}