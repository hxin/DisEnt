#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;
use Data::Dumper;




my($db,$host,$user,$psw,$file)=@ARGV;
open (MYFILE, $file);
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("select * from ontology where name like '%HDO%'");
$sth->execute;
my @row = $sth->fetchrow_array();
my $term_ref={};
$term_ref->{'ontology_id'}=$row[0];
$term_ref->{'def'}='';
$term_ref->{'comment'}='';
$term_ref->{'is_obsolete'}=0;
$term_ref->{'synonyms'}=[];
$term_ref->{'alt_ids'}=[];
$term_ref->{'xrefs'}=[];
$term_ref->{'parents'}=[];



while ( <MYFILE> ) {
	my $line=$_;
    chomp($line);
    if($line =~ m/^id:\s(.+)/){
    	$term_ref->{'acc'}=$1;
    }elsif($line =~ m/^name:\s(.+)/){
		$term_ref->{'name'}=$1;
	}elsif($line =~ m/^def:\s(.+)/){
		$term_ref->{'def'}=$1;
	}elsif($line =~ m/^comment:\s(.+)/){
		$term_ref->{'comment'}=$1;
	}elsif($line =~ m/^synonym:\s\"(.+)\".+/){
		push(@{$term_ref->{'synonyms'}},$1);
	}elsif($line =~ m/^alt_id:\s(.+)/){
		push(@{$term_ref->{'alt_ids'}},$1);
	}elsif($line =~ m/^xref:\s(.+)/){
		push(@{$term_ref->{'xrefs'}},$1);
	}elsif($line =~ m/^is_a:\s(DOID:\d+)\s.+/){
		push(@{$term_ref->{'parents'}},$1);
	}elsif($line =~ m/^is_obsolete:\s(.+)/){
		$term_ref->{'is_obsolete'}=1;
	}elsif($line =~ m/^subset:/){
		#do nothing
	}
}

#print Dumper($term_ref);
$sth = $dbh->prepare("insert into `ontology_term` (`ontology_id`,`id`,`name`,`def`,`comment`,`is_obsolete`) values (?,?,?,?,?,?);");
$sth->bind_param(1, $term_ref->{'ontology_id'});
$sth->bind_param(2, $term_ref->{'acc'});
$sth->bind_param(3, $term_ref->{'name'});
$sth->bind_param(4, $term_ref->{'def'});
$sth->bind_param(5, $term_ref->{'comment'});
$sth->bind_param(6, $term_ref->{'is_obsolete'});
$sth->execute();

##synonym
$sth = $dbh->prepare("insert into `ontology_term_synonym` (`term_id`,`term_synonym`) values (?,?);");
while(@{$term_ref->{'synonyms'}}){
	#print Dumper(@{$term_ref->{'synonyms'}});
	my $s=shift @{$term_ref->{'synonyms'}};
	$sth->bind_param(1, $term_ref->{'acc'});
	$sth->bind_param(2, $s);
	$sth->execute();
}


##dbxref
$sth = $dbh->prepare("insert into `ontology_term_dbxref` (`term_id`,`xref_dbname`,`xref_id`) values (?,?,?);");
while(@{$term_ref->{'xrefs'}}){	
	my $xref=shift @{$term_ref->{'xrefs'}};
	my ($xref_dbname,$xref_id)=split(/:/,$xref);
	$sth->bind_param(1, $term_ref->{'acc'});
	$sth->bind_param(2, $xref_dbname);
	$sth->bind_param(3, $xref_id);
	$sth->execute();
}

##parents
$sth = $dbh->prepare("insert into `ontology_term2term` (`term1_id`,`term2_id`,`relationship`) values (?,?,?);");
while(@{$term_ref->{'parents'}}){	
	my $p=shift @{$term_ref->{'parents'}};
	$sth->bind_param(1, $term_ref->{'acc'});
	$sth->bind_param(2, $p);
	$sth->bind_param(3, 'is_a');
	$sth->execute();
}