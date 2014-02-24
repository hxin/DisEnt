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
        if($line =~ m/^\[Term\]/){
        	#start
        	$start=1;
        	#print $line;
        	next READLINE;        
        }
		if($start){
			if($line =~ m/^id:\s(.+)/){
	        	$current_id=$1;
	        	$return{$current_id}={};
	        	#$return{$current_id}={'id'}->{$current_id};
	        	$return{$current_id}->{'synonyms'}=[];
	        	$return{$current_id}->{'xrefs'}=[];
	        	$return{$current_id}->{'parents'}=[];
	        	next READLINE;       
	        }elsif($line =~ m/^name:\s(.+)/){
	        	$return{$current_id}->{'name'}=$1;
	        	next READLINE;
	        }elsif($line =~ m/^def:\s(.+)/){
	        	$return{$current_id}->{'def'}=$1;
	        	next READLINE;
	        }elsif($line =~ m/^comment:\s(.+)/){
	        	$return{$current_id}->{'comment'}=$1;
	        	next READLINE;
	        }elsif($line =~ m/^synonym:\s\"(.+)\".+/){
	        	push(@{$return{$current_id}->{'synonyms'}},$1);
	        	next READLINE;
	        }elsif($line =~ m/^xref:\s(.+)/){
	        	push(@{$return{$current_id}->{'xrefs'}},$1);
	        	next READLINE;
	        }elsif($line =~ m/^is_a:\s(DOID:\d+)\s.+/){
	        	push(@{$return{$current_id}->{'parents'}},$1);
	        	next READLINE;
	        }elsif($line =~ m/^is_obsolete:\s(.+)/){
	        	$return{$current_id}->{'is_obsolete'}=$1;
	        	next READLINE;
	        }elsif($line =~ m/^subset:/){
	        	#do nothing
	        	next READLINE;
	        }elsif($line =~ m/^\n/ ){
	        	#end
	        	$start=0;
	        	$current_id=0;
	        	next READLINE;
			}
		}#end start
}

while (my ($do_acc, $hash_ref) = each(%return)){
#if(!defined($hash_ref->{'is_obsolete'})){
	foreach(@{$hash_ref->{'parents'}}){
		print $do_acc."\t".$_."\n";
	}
#}
	
	
	
}



