#!/usr/bin/perl

use strict;
use DBI;


my($db,$host,$user,$psw,$debug)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("select distinct phenotype_id,phenotype_description from ENSEMBL_v2p;");
if($debug eq 'y'){
	$sth = $dbh->prepare("select distinct phenotype_id,phenotype_description from ENSEMBL_v2p limit 100;");
}
$sth->execute();
my $dis_ref = {};
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."\t".$row[1]."\n";
}

