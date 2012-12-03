#!/usr/bin/env perl

use strict;

my $PREFIX = shift;

my %trait_map = (
	"YA" => "Y",
	"YC" => "Y",
	"YF" => "Y",
	"YI" => "Y",
	"YJ" => "Y",
	"YR" => "Y",
	"YR1B" => "Y",
	"MTA" => "MT",
	"MTC" => "MT",
	"MTD" => "MT",
	"MTE" => "MT",
	"MTF" => "MT",
	"MTG" => "MT",
	"MTH" => "MT",
	"MTH1" => "MT",
	"MTH13" => "MT",
	"MTH3" => "MT",
	"MTH30" => "MT",
	"MTH4" => "MT",
	"MTH5A" => "MT",
	"MTHV" => "MT",
	"MTI" => "MT",
	"MTJ" => "MT",
	"MTK" => "MT",
	"MTM" => "MT",
	"MTN" => "MT",
	"MTT" => "MT",
	"MTU" => "MT",
	"MTU2E" => "MT",
	"MTU4" => "MT",
	"MTU5" => "MT",
	"MTV" => "MT",
	"MTW" => "MT",
	"MTX" => "MT",
	"FG" => "FPG",
	"LDLC" => "TC",
	"NICO" =>"SMOK",
	"Neanderthal" => "NEAND",
	"PC" => "MPV",
	"SMAA" => "TASTE",
	"SMAN" => "TASTE",
	"SMCG" => "TASTE",
	"SMIA" => "TASTE",
	"SMUM" => "URINE",
	"TABI" => "TASTE",
	"TAQU" => "TASTE"
		);

opendir (my $dir, $PREFIX."sot_trait_descriptions");
my @files = readdir($dir);
		
foreach my $file (@files){
	if ($file =~ /(.+)\.html$/){
		my $sotkey = $1;
		open (my $in, "<", $PREFIX."sot_trait_descriptions/$file");
		my $text;
		while (<$in>){
			$text .= $_;
		}
		close $in;

		if ($trait_map{$sotkey}){
			open (my $out, ">>", $PREFIX."trait_descriptions/$trait_map{$sotkey}.html");
			print $out "$text</br>\n";
			close $out;
		}else{
			open (my $out, ">>", $PREFIX."trait_descriptions/$sotkey.html");
			print $out "$text</br>\n";
			close $out;
		}
	}
}
