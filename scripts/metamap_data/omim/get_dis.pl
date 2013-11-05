#!/usr/bin/perl

use strict;
use DBI;


my($db,$host,$user,$psw)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;

my $sth = $dbh->prepare("SELECT distinct description FROM OMIM_disease2gene where disorder_mim_acc!=0;");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	print $row[0]."\n\n"
}
