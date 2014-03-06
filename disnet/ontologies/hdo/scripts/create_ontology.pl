#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;

my($db,$host,$user,$psw)=@ARGV;

my $name='Human Disease Ontology (HDO)';
my $def='The Disease Ontology has been developed as a standardized ontology for human disease with the purpose of providing the biomedical community with consistent, reusable and sustainable descriptions of human disease terms, phenotype characteristics and related medical vocabulary disease concepts through collaborative efforts of researchers at Northwestern University, Center for Genetic Medicine and the University of Maryland School of Medicine, Institute for Genome Sciences.';
my $link='http://disease-ontology.org/';

my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("insert into ontology (`name`,`def`,`link`) values (?,?,?);");
$sth->bind_param(1, $name);
$sth->bind_param(2, $def);
$sth->bind_param(3, $link);
$sth->execute;
print $sth->{mysql_insertid};
exit;
