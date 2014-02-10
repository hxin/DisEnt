#!/usr/bin/perl

use strict;
use DBI;

my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $line;
my $name;
my $current_id;
my $current_des;

open FILE, "<", $file or die $!;

READLINE: while (<FILE>) {
	$line = $_;

	chomp($line);
	#Processing 00000000.tx.1: 5947|Metabolite levels
	if ( $line =~ m/^Processing.+:\s(\d+)\|(.+)/ ) {
		#$name=$1;
		#print "\n".$1."\t".description2id($dbh,$1);
		#print "\n".$1."\t".$2;
		$current_id=$1;
		$current_des=$2;
		#print "\n".$1;
		next READLINE;
	}
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



sub description2id{
	my ($dbh,$term)=@_;
	my $sth = $dbh->prepare("SELECT distinct phenotype_id FROM ENSEMBL_variation2phenotype where phenotype_description=?");
	$sth->execute($term);
	my @row = $sth->fetchrow_array;
	return $row[0];
}

sub hdoid2des{
	my $id=shift @_;
	my $sth = $dbh->prepare("select name from DO_terms where term_id=?; ");
	$sth->execute($id);
	my @row = $sth->fetchrow_array;
	return $row[0];
}
