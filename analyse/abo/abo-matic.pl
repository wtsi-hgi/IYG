#!/usr/bin/env perl

use strict;

my %infotext = (
	"A" => "You are likely blood type A. Type A blood can receive blood from types O and A, and can donate to A and AB.",
	"B" => "You are likely blood type B. Type B blood can receive blood from types O and B, and can donate to B and AB.",
	"B*" => "You have an uncommon combination of genotypes at this locus. We estimate you have an 80% chance of being type B. Type B blood can receive blood from types O and B, and can donate to B and AB.",
	"AB" => "You are likely blood type AB. Type AB is the universal recipient (can receive any other blood type), but can only be donated to other AB individuals.",
	"O" => "You are likely blood type O. Type O blood can only receive blood from other O individuals, but is the universal donor (can be given to anyone).",
	"Unknown" => "We were unable to determine your likely blood type. The genetic markers in this region are difficult to assay, so some samples didn't provide a strong enough signal for a prediction."
	);

my $aboped = shift;

#algorithm from https://docs.google.com/spreadsheet/ccc?key=0Aix0fqaSeLD1cHdJQ2RDa3hhZEJCSVA0V0Zsc2I5UkE&hl=en#gid=0
#LD for 7,6,3 GCG / CAA

print "Barcode\tTraitShortName\tBloodType\tInfoText\n";

open (my $in, "<", $aboped);
while (<$in>) {
	my @f = split;
	
	my $exp = "Unknown";
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
		#WTF is this?
		#print "$f[0]\t$f[6]$f[7]$f[8]$f[9]$f[10]$f[11]\n";
	}
	
	
	if ($f[12] eq "N" && $f[13] eq "N"){
		$exp = "Unknown";
	}elsif ($f[12] eq "-" && $f[13] eq "-"){
		#homoz del
		$exp = "O";
	}elsif ($f[12] eq "G"){
		if ($f[13] eq "G"){
			#hom WT
			$exp = $exp;
		}elsif ($f[13] eq "-"){
			#het del
			if ($exp eq "AB"){
				$exp="B*";
			}else{
				$exp=$exp;
			}
		}else{
			die "WTF? $_";
		}
	}else{
		die "WTF? $_";
	}
	print "$f[0]\tABO\t$exp\t$infotext{$exp}\n";
}

close $in;
