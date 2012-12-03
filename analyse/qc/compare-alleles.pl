use strict;

my %rc = (
	"A" => "T",
	"C" => "G",
	"G" => "C",
	"T" => "A",
	"0" => "0"
	);

my %a1;
my %a2;
open (my $in, "<", "ensembl-alleles.txt");
while (<$in>){
	my @f = split;
	$a1{$f[0]} = $f[3];
	$a2{$f[0]} = $f[4];
}
close $in;


open (my $in, "<", "iyg-2.bim");
while (<$in>){
	my @f = split;
	if (/MT/){
		print $_;
	}elsif ($f[4] eq $rc{$f[5]}){
		chomp;
		print "$_ ? \n";
	}elsif ($a1{$f[1]} eq $f[4] && $a2{$f[1]} eq $f[5] ||
		$a1{$f[1]} eq $f[5] && $a2{$f[1]} eq $f[4]){
		print "$_";
	}elsif($a1{$f[1]} eq $rc{$f[4]} && $a2{$f[1]} eq $rc{$f[5]} ||
		$a1{$f[1]} eq $rc{$f[5]} && $a2{$f[1]} eq $rc{$f[4]}){
		print "$f[0]\t$f[1]\t$f[2]\t$f[3]\t$rc{$f[4]}\t$rc{$f[5]}\n";
	}else{
		die "AIEEE! $f[1]\n";
	}
}