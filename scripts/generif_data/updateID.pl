#!/usr/bin/perl -w

use strict;
use DBI;
use Data::Dumper;

my($db,$host,$user,$psw)=@ARGV;

$db='xin3';
$host='nrg.inf.ed.ac.uk';
$user='xin';
$psw='12091209';


my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("SELECT distinct do_acc FROM GeneRIF_disease2gene;");
$sth->execute();
my @ids;
while ( my @row = $sth->fetchrow_array ) {
	push(@ids,$row[0]);
}

#update
foreach my $id(@ids){
	my $sth = $dbh->prepare("select term_id from DO_altids where alt_id=?;");
	$sth->execute($id);
	if(my @row = $sth->fetchrow_array){
		$sth = $dbh->prepare("UPDATE GeneRIF_disease2gene SET do_acc=?
				WHERE do_acc=?");
		$sth->execute($row[0],$id);
	}
}

 
	
exit;

