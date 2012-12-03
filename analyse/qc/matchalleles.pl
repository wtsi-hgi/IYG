use strict;

my %rc = (
	"A" => "T",
	"C" => "G",
	"G" => "C",
	"T" => "A"
	);


open (my $in, "<", "riskalleles.txt");
my %ra;
while (<$in>){
	my @f = split;
	$ra{$f[0]} = $f[1];
}

open (my $in, "<", "qt-allele-frq.txt");
<$in>; #header
while (<$in>){
	my @f = split;
	my $bonus = "";
	if ($f[1] eq $rc{$f[3]}){
		$bonus = "?";
	}
	my $r;
	if ($ra{$f[0]} eq $f[1] || $ra{$f[0]} eq $rc{$f[1]}){
		$r = $f[2];
	}elsif ($ra{$f[0]} eq $f[3] || $ra{$f[0]} eq $rc{$f[3]}){
		$r = 1-$f[2];
	}else{
		die "$f[0]\n";
	}
	if ($ra{$f[0]} eq $rc{$f[1]} || $ra{$f[0]} eq $rc{$f[3]}){
		print STDERR "needed to swap $f[0]!\n";
	}
	print "$f[0]\t$ra{$f[0]}\t$r$bonus\n";
	
}