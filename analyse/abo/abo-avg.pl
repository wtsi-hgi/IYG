use strict;

my %markers = (
	"rs8176747" => 1,
	"rs8176746" => 1,
	"rs8176743" => 1
	);
	
my %sum_y;
my %sum_x;
my %str;
my %num;

open (my $in, "<", "ALL_assay_summary.fakebarcode.tsv.txt");
while (<$in>){
	my @fields = split /\t|\n/;
	if ($markers{$fields[11]}){
		if ($sum_y{$fields[4]}){
			$sum_x{$fields[4]} += $fields[3];
			$sum_y{$fields[4]} += $fields[6];
			$num{$fields[4]} ++;
			$str{$fields[4]} .= "\t$fields[3]\t$fields[6]";
		}else{
			$sum_x{$fields[4]} = $fields[3];
			$sum_y{$fields[4]} = $fields[6];
			$num{$fields[4]} = 1;
			$str{$fields[4]} = "$fields[3]\t$fields[6]";
		}
	}
}
close $in;

foreach my $ind (keys %sum_y){
	my $avgy = $sum_y{$ind}/$num{$ind};
	my $avgx = $sum_x{$ind}/$num{$ind};
	if ($num{$ind} == 3){
		print "$ind\t$str{$ind}\t$avgx\t$avgy\n";
	}
}