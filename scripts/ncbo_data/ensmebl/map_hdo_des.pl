#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;

my @ids;
my $table='NCBO_ensembl2do_raw';
my $sth = $dbh->prepare("select distinct do_acc from $table");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	push(@ids,$row[0]);
}

foreach my $id(@ids){	
	my $name=hdoid2des($id);
	$sth = $dbh->prepare("update NCBO_ensembl2do_raw set `do_description`=? where `do_acc`=?");
	$sth->execute($name,$id);
}



sub pid2des{
	my $id=shift @_;
	my $sth = $dbh->prepare("select phenotype_description from ENSEMBL_variation2phenotype where phenotype_id=?; ");
	$sth->execute($id);
	my @row = $sth->fetchrow_array;
	return $row[0];
}

sub hdoid2des($id){
	my $id=shift @_;
	my $sth = $dbh->prepare("select name from DO_terms where term_id=?; ");
	$sth->execute($id);
	my @row = $sth->fetchrow_array;
	return $row[0];
}

