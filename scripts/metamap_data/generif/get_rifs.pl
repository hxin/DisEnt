#!/usr/bin/perl

use strict;
use DBI;


my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("SELECT id,gene_id,rif FROM GeneRIF_basic;");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."|".$row[1]."|".$row[2]."\n\n"
}

