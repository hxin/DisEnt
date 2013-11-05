#!/usr/bin/perl

use strict;
use Data::Dumper;



my %return;
my $line;
my $start=0;
my $line_count=0;
my $current_id;
READLINE:while ( <> ) {
        $line=$_;
        chomp($line);
#       print Dumper(%return) if $line_count++==100;
#		last if $line_count++==3;
#		exit if $line_count>100;
        if($line =~ m/<cd:DOID>(\d+)/){
        	print "\nDOID:".$1;
        	next READLINE;        
        }elsif($line =~ m/<cd:GeneID>(\d+)/){
		print "\t".$1;
        	next READLINE;
	}elsif($line =~ m/<cd:PubMedID>(\d+)/){
		print "\t".$1;
        	next READLINE;
	}elsif($line =~ m/<cd:GeneRIF>(.+)\s/){
		print "\t".$1;
        	next READLINE;
	}

		
}

	



