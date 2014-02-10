#!/usr/bin/perl

use strict;
use DBI;

my ($file)=@ARGV;
#my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $line;
my $current_id;
my $current_des;

open FILE, "<", $file or die $!;
READLINE: while (<FILE>) {
	$line = $_;
	chomp($line);
	#Processing 00000000.tx.1: 17,20-lyase deficiency, isolated
	if ( $line =~ m/^Processing.+:\s(\d+)\|(.+)/ ) {
		$current_id=$1;
		$current_des=$2;
		next READLINE;
		#if($1 ne '{?'){
		#	my $id=description2id($dbh,$1);
		#	if($id eq ''){
		#		$id=description2id($dbh,'{?'.$1);
		#		print "\n".'{?'.$1."\t".$id;
		#	}else{
		#		print "\n".$1."\t".$id;
		#	}
		#	next READLINE;
		#}

	}
	#Processing 00000000.tx.2: Keratoderma, palmoplantar, punctate type 3
	if ( $line =~ m/^Processing.+tx\.(\d+):\s(.+)/ ) {
		if($1>1){
			$current_des .= $2;
		}
		next READLINE;
	}
	
	#    770  DOID225:syndrome
	if ( $line =~ m/^\s+(\d+)\s+DOID(\d+):(.+)/ ) {
		my $do_id="DOID:$2";
		#print "\t".$id."\t".hdoid2des($id)."\t".$1;
		print $current_id,"\t",$current_des,"\t",$do_id,"\t",$3,"\t",$1,"\n";
		next READLINE;
	}
	
}




