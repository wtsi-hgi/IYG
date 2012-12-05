#!/usr/bin/env perl

use strict;
use warnings;

my $snpchrpos_file = shift;
my $pedmapout = shift;

my %snp2chr;
my %snp2pos;
my $snpchrpos;
open($snpchrpos, "<", $snpchrpos_file) or die "could not open SNP-CHR-POS file $snpchrpos_file\n";
foreach my $line (<$snpchrpos>) {
    chomp $line;
    my ($snp, $chr, $pos) = split /\t/, $line;
    $snp2chr{$snp} = $chr;
    $snp2pos{$snp} = $pos;
}
close $snpchrpos;

my %data; 
my %snps; 
foreach my $line (<>) {
    chomp $line; 
    my ($samp, $plate, $snp, $gt) = split(/\t/, $line);
    if(exists($data{$samp}{gt}{$snp})) {
	my $oldplate = $data{$samp}{plate};
	print STDERR "have data for sample $samp at snp $snp from plate $plate, but data already exists from plate $oldplate... ";
	if($oldplate eq $plate) {
	    print STDERR "merging duplicate data from the same plate\n";
	    my $oldgt = $data{$samp}{gt}{$snp};
	    if ($oldgt =~ m/^([ACGT-]):([ACGT-])$/) {
		my $olda1 = $1;
		my $olda2 = $2;
		if($gt =~ m/^([ACGT-]):([ACGT-])$/) {
		    my $a1 = $1;
		    my $a2 = $2;
		    print STDERR "have alleles from both genotypes\n";
		    if( ($olda1 eq $a1) && ($olda2 eq $a2) ) {
			print STDERR "they are identical, keeping what we have\n";
			next;
		    } else {
			print STDERR "they are different, setting to missing\n";
			$data{$samp}{gt}{$snp} = "Replicate Disagreement";
			next;
		    }
		} else {
		    print STDERR "new gt missing, keeping old\n";
		    next;
		}
	    } else {
		print STDERR "old gt missing, setting new\n";
	    }
	} else {
	    if($oldplate =~ m/^9/) {
		print STDERR "keeping old data and dropping data from plate $plate\n";
		next;
	    } else {
		print STDERR "dropping old data and replacing it with data from plate $plate\n";
	    }
	}
    }
    print STDERR "recording genotype for sample $samp for plate $plate at snp $snp\n";
    $data{$samp}{plate} = $plate; 
    $data{$samp}{gt}{$snp} = $gt;
    $snps{$snp}=1;
}

my @snps = sort {$a cmp $b} keys %snps;

open MAP, ">$pedmapout.map";
print MAP join("\n",map {join("\t", [$snp2chr{$_}, $_, $snp2pos{$_}] )} @snps)."\n";
close MAP;

open PED, ">$pedmapout.ped";
foreach my $sample (sort {$a cmp $b} keys %data) { 
    print PED $sample."\t";
    print PED $data{$sample}{plate};
    foreach my $snp (@snps) { 
	my $a1="N";
	my $a2="N";
	if(exists($data{$sample}{gt}{$snp})) {
	    my $gt = $data{$sample}{gt}{$snp};
	    if($gt =~ m/^([ACGT-]):([ACGT-])$/) { 
		$a1 = $1;
		$a2 = $2;
	    } else {
		die "found unrecognised genotype value $gt. bailing out!\n" unless ($gt =~ m/^(No Call|Invalid|NTC|Replicate Disagreement)$/);
	    }
	}
	print PED "\t".$a1."\t".$a2;
    } 
    print PED "\n";
}
