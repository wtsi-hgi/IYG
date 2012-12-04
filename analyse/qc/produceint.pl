use strict;
open (my $in, "<", "sorted-raw-input.txt");
open (my $int, ">", "all-data.int");
open (my $ped, ">", "all-data.tped");
open (my $tfam, ">", "all-data.tfam");
my $currsnp;
my $line;
my $pedline;
my $counter = 1;
my $tfamfinished = 0;
my %found;
while (<$in>){
	if (/NTC/){
		next;
	}
	my @f = split /\t|\n/;
	
	if ($f[11] ne $currsnp){
		if ($currsnp){
			$tfamfinished = 1;
			print $int "$line\n";
			print $ped "$pedline\n";
		}
		$currsnp = $f[11];
		$line = "$f[11]";
		$pedline = "1\t$f[11]\t$counter\t$counter";
		$counter++;
	}
	
	if (!$tfamfinished){
		if ($found{$f[4]}){
			$f[4] .= "a";
		}
		print $tfam "$f[4]\t$f[4]\t0\t0\t0\t0\n";
		$found{$f[4]} = 1;
	}
	
	if ($f[10] eq "No Call" || $f[10] eq "Invalid"){
		$pedline .= "\t0\t0";
	}else{
		my @geno = split /:/, $f[10];
		$pedline .= "\t$geno[0]\t$geno[1]";
	}
	$line .= "\t$f[3]\t$f[6]";
}
print $int "$line\n";
print $ped "$pedline\n";
