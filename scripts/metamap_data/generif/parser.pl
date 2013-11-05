#!/usr/bin/perl
use strict;
my $line;
my $rif_id;
my $gene_id;
while (<>) {
	$line = $_;
	chomp($line);
	if ( $line =~ m/^Processing.+:\s(\d+)\|(\d+)\|.+/ ) {
		$rif_id=$1;
		$gene_id=$2;
	}elsif ( $line =~ m/^\s+(\d+)\s+DOID(\d+):(.+)/ ) {
		print $rif_id."\t".$gene_id."\tDOID:".$2."\t".$1."\n";
	}
}



