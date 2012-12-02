use strict;
open (my $in, "<", "iyg-2.bim");
while (<$in>){
	my @f = split;
	if ($f[0] eq "24" || $f[0] eq "26"){
		print "$f[1]\t$f[4],$f[5]\t1\n";
	}else{
		print "$f[1]\t$f[4]$f[4],$f[4]$f[5],$f[5]$f[5]\t2\n";
	}
}
close $in;