#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

use PadWalker;
use Data::Dumper;


my($db,$host,$user,$psw)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
#my $sth = $dbh->prepare("select distinct phenotype_id,phenotype_description from ENSEMBL_variation2phenotype limit 100;");
my $sth = $dbh->prepare("select distinct phenotype_id,phenotype_description from ENSEMBL_variation2phenotype;");
$sth->execute();
my $dis_ref = {};
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."\t".$row[1]."\n";
}

