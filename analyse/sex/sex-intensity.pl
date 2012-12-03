use strict;

my %ymarkers = (
	"rs2032597" => 1,
	"rs35284970" => 1,
	"rs2032658" => 1,
	"rs13447352" => 1,
	"rs9786184" => 1,
	"rs2032652" => 1,
	"rs2534636" => 1
	);


my %sum_y;
my %num_y;
my %calls;
open (my $in, "<", "ALL_assay_summary.fakebarcode.tsv.txt");
while (<$in>){
	my @fields = split /\t|\n/;
	if ($ymarkers{$fields[11]}){
		if ($sum_y{$fields[4]}){
			$sum_y{$fields[4]} += $fields[3];
			$sum_y{$fields[4]} += $fields[6];
			$num_y{$fields[4]} += 2;
			if (($fields[10] =~ m/[ACGT]:[ACGT]/)){
				$calls{$fields[4]} += 2;
			}
		}else{
			$sum_y{$fields[4]} = $fields[3];
			$sum_y{$fields[4]} = $fields[6];
			$num_y{$fields[4]} = 2;
			if (($fields[10] =~ m/[ACGT]:[ACGT]/)){
				$calls{$fields[4]} = 2;
			}
		}
	}
}
close $in;

foreach my $ind (keys %sum_y){
	my $avgcalls = $calls{$ind}/$num_y{$ind};
	my $avgy = $sum_y{$ind}/$num_y{$ind};
	print "$ind\t$avgcalls\t$avgy\t$num_y{$ind}\n";
}