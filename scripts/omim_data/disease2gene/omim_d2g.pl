#!/usr/bin/perl

use strict;
use DBI;
my($db,$host,$user,$psw,$file)=@ARGV;
#my $file_path = './temp.0.txt';
my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
my $line;
my $current_id;
my $current_name;
my $start;
open FILE, "<", $file or die $!;
READLINE: while (<FILE>) {
	$line = $_;
	chomp($line);
	my ($dis_name,$gene_symbols,$locus_mim_acc,$location) = split(/\|/, $line);
	my $disorder_mim_acc;

	if($dis_name =~ m/(.+),\s(\d{6})\s?\(\d\)/){
		$dis_name=$1;
		$disorder_mim_acc=$2;
		if($2==$locus_mim_acc){
			$locus_mim_acc='';
		}
	}elsif($dis_name =~ m/(.+)\s\([1234]\)/){
		$dis_name=$1;
		if(isPt($dbh,$locus_mim_acc)){
			$disorder_mim_acc=$locus_mim_acc;
			$locus_mim_acc='';
		}else{
			$disorder_mim_acc='';
		}
	}
	#print $dis_name."\t".$disorder_mim_acc."\n";
	my @gene_symbols= split(/, /, $gene_symbols);
	foreach my $s(@gene_symbols){
		print $dis_name."\t".$disorder_mim_acc."\t".$s."\t".$locus_mim_acc."\t".$location."\n";
	}
}


sub isPt(){
	my ($dbh,$mim_acc)=@_;
	my $sth = $dbh->prepare("select type from $db.OMIM_mim2gene where mim_acc=?;");
	$sth->execute($mim_acc);
	my @row = $sth->fetchrow_array;
	if($row[0] eq 'phenotype' or $row[0] eq 'gene/phenotype'){
		return 1;
	}else{
		return 0;
	}
}




#17,20-lyase deficiency, isolated, 202110 (3)|CYP17A1, CYP17, P450C17|609300|10q24.32
#Histiocytosis-lymphadenopathy plus syndrome, 602782 (3)|HJCD, HCLAP|602782|11q25
#{Autism susceptibility, X-linked 4} (4)|DELXp22.11, CXDELp22.11, AUTSX4|300830|Xp22.11
#Cone-rod dystrophy 6, 601777(3)|GUCY2D, GUC2D, LCA1, CORD6, RCD2|600179|17p13.1
