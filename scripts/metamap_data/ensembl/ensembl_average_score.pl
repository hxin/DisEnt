#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

my($db,$host,$user,$psw,$file)=@ARGV;
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;

my $count=0;
my $line;
my $omim2do_ref={};
my $result_ref={};
my $result_eq_ref={};
my $table='MetaMap_ensembl2do_raw';
my $sth = $dbh->prepare("
select phenotype_id,do_acc,score from $table");
$sth->execute();
while ( my @row = $sth->fetchrow_array ) {
	$omim2do_ref->{$row[0]}->{$row[1]} += $row[2];

}
#print Dumper(%{$omim2do_ref});exit;

foreach my $mim_acc(keys %$omim2do_ref){
	my $max_score=0;
	my $max_do;
	foreach my $do_acc(keys %{$omim2do_ref->{$mim_acc}}){
		if($omim2do_ref->{$mim_acc}->{$do_acc} > $max_score){
			$max_do=$do_acc;
			$max_score=$omim2do_ref->{$mim_acc}->{$do_acc};
			$result_ref->{$mim_acc}=[];
			push(@{$result_ref->{$mim_acc}},$do_acc);
		}elsif($omim2do_ref->{$mim_acc}->{$do_acc} == $max_score){
			push(@{$result_ref->{$mim_acc}},$do_acc);
		}
	}
}

#print Dumper(%{$result_ref});exit;


foreach my $key(keys %$result_ref){
	foreach(@{$result_ref->{$key}}){
		my $d=$_;
		print $key."\t".pid2des($key)."\t".$d."\t".hdoid2des($d)."\n";
	}
	
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



#46,XY GONADAL DYSGENESIS, PARTIAL, WITH MINIFASCICULAR NEUROPATHY	607080	DOID:14448	46 XY gonadal dysgenesis	833	DOID:870	neuropathy	578
