#!/usr/bin/perl

use strict;
use DBI;


my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("select distinct phenotype_description from ENSEMBL_variation2phenotype;");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."\n\n"
}

