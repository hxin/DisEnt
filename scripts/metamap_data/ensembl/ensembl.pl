#!/usr/bin/perl

use strict;
use DBI;

my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $line;
my $name;
open FILE, "<", $file or die $!;
READLINE: while (<FILE>) {
	$line = $_;
	chomp($line);
	#Processing 00000000.tx.1: 17,20-lyase deficiency, isolated
	if ( $line =~ m/^Processing.+:\s(.+)/ ) {
		#$name=$1;
		print "\n".$1."\t".description2id($dbh,$1);
		#print "\n".$1;
		next READLINE;
	}
	
	#    770  DOID225:syndrome
	if ( $line =~ m/^\s+(\d+)\s+DOID(\d+):(.+)/ ) {
		my $id="DOID:$2";
		print "\t".$id."\t".hdoid2des($id)."\t".$1;
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
