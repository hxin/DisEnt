#!/usr/bin/perl -w

use strict;
use warnings;
use DBI;

my($db,$host,$user,$psw)=@ARGV;


my $name='variation';
my $des='ensembl variation database';
my $link='http://www.ensembl.org/info/genome/variation/index.html';

my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("insert into source (`name`,`description`,`link`) values (?,?,?);");
$sth->bind_param(1, $name);
$sth->bind_param(2, $des);
$sth->bind_param(3, $link);
$sth->execute;
print $sth->{mysql_insertid};
exit;
