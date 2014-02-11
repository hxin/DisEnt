#!/usr/bin/perl -w
use strict;
use DBI;
my $line;
while(<>){
 	$line = $_;
	chomp($line);
	#856290	YPR161C
	if ( $line =~ m/(\d+)\s(.+)/ ) {
		print "4932"."\t".$1."\t".$2."\n";
	}
}

