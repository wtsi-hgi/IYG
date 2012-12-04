#!/usr/bin/env perl

use strict;
use warnings;

use Text::Iconv;
my $converter = Text::Iconv->new("utf-8","windows-1251");

use Spreadsheet::XLSX;

my $outsep = "\t";
my $missing = "NA";

my $outfh;
open $outfh, ">ALL_assay_summary.tsv.txt" or die "could not open output file\n";

my %header2col;
my %col2header;
my @data;
my %allheaders;

foreach my $platenum ( 1 .. 9) {
    foreach my $platelet ( "A", "B" ) {
	print STDERR "loading XLSX for plate_$platenum$platelet\n";
	my $excel = Spreadsheet::XLSX->new('plate_'.$platenum.$platelet.'/assay_summary_Sanger_Langley_plate_'.$platenum.$platelet.'.xlsx', $converter);
	
	foreach my $sheet (@{$excel -> {Worksheet}}) {
	    # printf $outfh ("Sheet: %s\n", $sheet->{Name});
	    if( $sheet->{Name} eq "Sheet1" ) {
		$sheet -> {MaxRow} ||= $sheet -> {MinRow};
		die "unexpected MinRow or MaxRow for $platenum$platelet\n" unless ( $sheet -> {MaxRow} > 2 && $sheet -> {MinRow} == 0 );
		# process header rows 
		foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
		    my @headers;
		    if(exists($sheet->{Cells}[0][$col]->{Val}) && !($sheet->{Cells}[0][$col]->{Val} =~ m/^[[:space:]]+$/)) {
			push @headers, $sheet->{Cells}[0][$col]->{Val};
		    }
		    if(exists($sheet->{Cells}[1][$col]->{Val}) && !($sheet->{Cells}[1][$col]->{Val} =~ m/^[[:space:]]+$/)) {
			push @headers, $sheet->{Cells}[1][$col]->{Val};
		    }
		    if(exists($sheet->{Cells}[2][$col]->{Val}) && !($sheet->{Cells}[2][$col]->{Val} =~ m/^[[:space:]]+$/)) {
			push @headers, $sheet->{Cells}[2][$col]->{Val};
		    }
		    if(@headers > 0) {
			my $header =  join(" - ", @headers);
			$header2col{$header} = $col;
			$col2header{$col} = $header;
			$allheaders{$header} = 1;
		    }
		}
		
		# process data
		foreach my $row (3 .. $sheet -> {MaxRow}) {
		    $sheet -> {MaxCol} ||= $sheet -> {MinCol};
		    my %rowdata;
		    foreach my $col ($sheet -> {MinCol} ..  $sheet -> {MaxCol}) {
			my $cell = $sheet -> {Cells} [$row] [$col];
			if ($cell) {
			    my $header = $col2header{$col};
			    my $value = $cell->{Val};
			    $rowdata{$header} = $value;
			}
		    }
		    # insert "extra" metadata column
		    $allheaders{"Plate"} = 1;
		    $rowdata{"Plate"} = $platenum.$platelet;
		    push @data, \%rowdata;
		}
	    } else {
		print STDERR "skipping sheet $sheet->{Name} for plate_$platenum$platelet\n";
	    }
	}	
    }
}

my @headers = keys %allheaders;
print $outfh join($outsep, @headers)."\n";
foreach my $rd (@data) {
    my @rowdata;
    foreach my $header (@headers) {
	if(exists($rd->{$header})) {
	    push @rowdata, $rd->{$header};
	} else {
	    push @rowdata, $missing;
	}
    }
    print $outfh join($outsep, @rowdata)."\n";
}
close $outfh;
