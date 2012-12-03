use strict;

open (my $in, "<", "plink.genome");
<$in>; #header
my %max;
while (<$in>){
	my @f = split;
	if ($f[11] > $max{$f[0]}){
		$max{$f[0]} = $f[11];
	}
	if ($f[11] > $max{$f[2]}){
		$max{$f[2]} = $f[11];
	}
}
close $in;

foreach my $key (keys %max){
	print "$key\t$max{$key}\n";
}