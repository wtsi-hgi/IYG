use strict;

#algorithm from https://docs.google.com/spreadsheet/ccc?key=0Aix0fqaSeLD1cHdJQ2RDa3hhZEJCSVA0V0Zsc2I5UkE&hl=en#gid=0
#LD for 7,6,3 GCG / CAA

open (my $in, "<", "abo.ped");
while (<$in>){
	my @f = split;
	
	my $exp = "U";
	if (($f[6] ne $f[7] || $f[6] eq "N") 
	&& ($f[8] ne $f[9] || $f[8] eq "N") 
	&& ($f[10] ne $f[11]) || $f[10] eq "N"){
		$exp = "AB";
	}elsif ((($f[6] eq "G" && $f[7] eq "G") || $f[6] eq "N") &&
	(($f[8] eq "C" && $f[9] eq "C") || $f[8] eq "N") &&
	(($f[10] eq "G" && $f[11] eq "G") || $f[10] eq "N" || $f[10] ne $f[11])){
		$exp = "A";
	}elsif ((($f[6] eq "C" && $f[7] eq "C") || $f[6] eq "N") &&
	(($f[8] eq "A" && $f[9] eq "A") || $f[8] eq "N") &&
	(($f[10] eq "A" && $f[11] eq "A") || $f[10] eq "N")){
		$exp = "B";
	}else{
		#print "$f[0]\t$f[6]$f[7]$f[8]$f[9]$f[10]$f[11]\n";
	}
	
	
	if ($f[12] eq "N"){
		print "$f[0]\tU\n";
	}elsif ($f[12] eq "-" && $f[13] eq "-"){
		#homoz del
		print "$f[0]\tO\n";
	}elsif ($f[12] eq "G"){
		if ($f[13] eq "G"){
			#hom WT
			print "$f[0]\t$exp\n";
		}elsif ($f[13] eq "-"){
			#het del
			if ($exp eq "AB"){
				print "$f[0]\tB*\n";
			}else{
				print "$f[0]\t$exp\n";
			}
		}else{
			die "WTF? $_";
		}
	}else{
		die "WTF? $_";
	}
}
