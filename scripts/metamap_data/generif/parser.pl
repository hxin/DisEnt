#!/usr/bin/perl
use strict;
my $line;


my $current_id;
my $current_des;
READLINE:while (<>) {
	$line = $_;
	chomp($line);
	#Processing 00000000.tx.1: 17,20-lyase deficiency, isolated
	if ( $line =~ m/^Processing.+:\s(\d+)\|(.+)/ ) {
		$current_id=$1;
		$current_des=$2;
		next READLINE;		
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
	
#	$line = $_;
#	chomp($line);
#	if ( $line =~ m/^Processing.+:\s(\d+)\|(\d+)\|.+/ ) {
#		$rif_id=$1;
#		$gene_id=$2;
#	}elsif ( $line =~ m/^\s+(\d+)\s+DOID(\d+):(.+)/ ) {
#		print $rif_id."\t".$gene_id."\tDOID:".$2."\t".$1."\n";
#	}
}



