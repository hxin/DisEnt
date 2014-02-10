#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

use PadWalker;
use Data::Dumper;


my($db,$host,$user,$psw)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
#my $sth = $dbh->prepare("SELECT distinct id,rif FROM GeneRIF_basic limit 100;");
my $sth = $dbh->prepare("SELECT distinct id,rif FROM GeneRIF_basic;");
$sth->execute();
my $dis_ref = {};
while ( my @row = $sth->fetchrow_array ) {
	$row[1] =~ s/\n//gi;
	print $row[0]."\t".$row[1]."\n";
}

