#!/usr/bin/perl -w
##############################
###############################

use strict;
use DBI;

my($db,$host,$user,$psw)=@ARGV;


############Create database connection
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $sth = $dbh->prepare("select distinct variation_id from ENSEMBL_variation;");
$sth->execute();
my @vars;
while ( my @row = $sth->fetchrow_array ) {
	push(@vars,$row[0]);
}



foreach my $var(@vars){
	##overlap
	$sth=$dbh->prepare("
(SELECT distinct variation_id,ensembl_id, 'o' as position FROM ENSEMBL_variation as v inner join ENSEMBL_human_gene as g
on v.chr=g.chr and v.start>=g.start and v.end <=g.end where variation_id=?)
union all
(select variation_id,ensembl_id,'d' as position from ENSEMBL_human_gene as g,ENSEMBL_variation as v
where g.chr=v.chr and g.start>v.end and variation_id=?
order By ABS(g.start-v.end) Asc limit 1)
union all
(select variation_id,ensembl_id,'u' as position 
from ENSEMBL_human_gene as g,ENSEMBL_variation as v
where g.chr=v.chr and g.end<v.start and variation_id=? 
order By ABS(g.end-v.start) Asc limit 1)
;");
	$sth->execute($var,$var,$var);
	while ( my @row = $sth->fetchrow_array ) {
		print $row[0]."\t".$row[1]."\t".$row[2]."\n";
	}
	
}


exit;

foreach my $var(@vars){
	##overlap
	$sth=$dbh->prepare("SELECT distinct variation_id,ensembl_id FROM ENSEMBL_variation as v inner join ENSEMBL_human_gene as g
	on v.chr=g.chr and v.start>=g.start and v.end <=g.end where variation_id=?");
	$sth->execute($var);
	while ( my @row = $sth->fetchrow_array ) {
		print $row[0]."\t".$row[1]."\t"."o"."\n";
	}
	
	##down
	$sth=$dbh->prepare("select variation_id,ensembl_id from ENSEMBL_human_gene as g,ENSEMBL_variation as v
		where g.chr=v.chr and g.start>v.end and variation_id=?
		order By ABS(g.start-v.end) Asc limit 1");
	$sth->execute($var);
	while ( my @row = $sth->fetchrow_array ) {
		print $row[0]."\t".$row[1]."\t"."d"."\n";
	}

	##up
	$sth=$dbh->prepare("select variation_id,ensembl_id from ENSEMBL_human_gene as g,ENSEMBL_variation as v
		where g.chr=v.chr and g.end<v.start and variation_id=? order By ABS(g.end-v.start) Asc limit 1;");
	$sth->execute($var);
	while ( my @row = $sth->fetchrow_array ) {
		print $row[0]."\t".$row[1]."\t"."u"."\n";
	}

}
