use strict;

open (my $in, "<", "master-snp-info.txt");
my %genos;
<$in>; #header
while (<$in>){
	my @f = split;
	my @g = split /,/, $f[1];
	$genos{$f[0]} = \@g;
}
close $in;

open (my $in, "<","snptraittemplate.txt");
<$in>; #header
while (<$in>){
	my @f = split;
	if (!$genos{$f[0]}){
		#SNP failed QC?
		print STDERR "$f[0]\n";
		next;
	}
	if (-e "qt/$f[1].grovebeta"){
		open (my $b, "<", "qt/$f[1].grovebeta");
		my $ra; my $beta;
		while (<$b>){
			my @bf = split;
			if ($bf[0] eq $f[0]){
				$ra = $bf[1];
				$beta = $bf[2];
			}
		}
		if ($ra){
			foreach my $g (@{$genos{$f[0]}}){
				my @alleles = split //, $g;
				if ($alleles[0] eq $ra && $alleles[1] eq $ra){
					#effect homoz
					my $e = 2*$beta;
					print "$f[0]\t$f[1]\t$g\t$e\n";
				}elsif ($alleles[0] eq $ra || $alleles[1] eq $ra){
					#het
					print "$f[0]\t$f[1]\t$g\t$beta\n";
				}elsif ($alleles[0] eq $alleles[1]){
					#ref homoz
					print "$f[0]\t$f[1]\t$g\tRef\n";
				}else{
					die "Alleles are wonky? $f[0] $ra $g\n";
				}
			}
		}else{
			die "Couldn't find expected beta! $f[0] $f[1]\n";
		}
	}else{
		foreach my $g (@{$genos{$f[0]}}){
			print "$f[0]\t$f[1]\t$g\tNA\n";
		}
	}
}