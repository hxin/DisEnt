#!/usr/bin/perl

use strict;
use DBI;


my($db,$host,$user,$psw,$debug)=@ARGV;

my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("SELECT id,rif FROM GeneRIF_basic;");

if($debug eq 'y'){
	$sth = $dbh->prepare("SELECT id,rif FROM GeneRIF_basic limit 100;");
}
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."|".$row[1]."\n\n"
}

