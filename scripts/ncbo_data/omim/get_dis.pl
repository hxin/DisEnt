#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

use PadWalker;
use Data::Dumper;



my($db,$host,$user,$psw,$debug)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
#my $sth = $dbh->prepare("SELECT distinct disorder_mim_acc,description FROM OMIM_disease2gene where disorder_mim_acc!=0 limit 100;");
my $sth = $dbh->prepare("SELECT distinct disorder_mim_acc,description FROM OMIM_disease2gene where disorder_mim_acc!=0;");
if($debug eq 'y'){
	$sth = $dbh->prepare("SELECT distinct disorder_mim_acc,description FROM OMIM_disease2gene where disorder_mim_acc!=0 limit 100;");
}

$sth->execute();

while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."\t".$row[1]."\n";
}

