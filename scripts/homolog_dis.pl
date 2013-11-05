#!/usr/bin/perl -w
##############################
#xin 11 Oct 2012
#the script is used to create model species disease gene association table
#need to run homologues_pull first!
###############################

use strict;
use DBI;
use Data::Dumper;

my($db,$host,$user,$psw,$species)=@ARGV;
my @species=split(/,/, $species);
my @species_list;
my %species_names;
foreach(@species){
	my ($f,$s)=split(/:/, $_);
	push(@species_list,$f);
	$species_names{$f}=$s;
}


############Edit this to add more species. The name can be found in Ensembl Compara in table [genomedb]
#my @species_list=("drosophila_melanogaster","rattus_norvegicus","mus_musculus","saccharomyces_cerevisiae","danio_rerio","caenorhabditis_elegans");
#my %species_names = ( "drosophila_melanogaster" => "fly",
#        			  "rattus_norvegicus" => "rat",
#          			  "mus_musculus" => "mouse",
#         			  "saccharomyces_cerevisiae" =>"yeast",
#				"danio_rerio" => "zebrafish","caenorhabditis_elegans" => "C_elegans",
#					"caenorhabditis_elegans" => "C_elegans");
#my @species_list=("drosophila_melanogaster","mus_musculus");
#my %species_names = ( "drosophila_melanogaster" => "fly",
#          			  "mus_musculus" => "mouse"
#         			  );



############Create database table

my $dbh   = DBI->connect ( "dbi:mysql:database=$db;host=$host;port=3306" , $user , $psw ) or die $DBI::errstr;
##OMIM
foreach(@species_list){
	my $fullName=$_;
	my $shortName=$species_names{$fullName};

	##ensembl
	$dbh->do("DROP TABLE IF EXISTS OMIM_${shortName}_gene2disease_ensembl;");
	$dbh->do("create table OMIM_${shortName}_gene2disease_ensembl as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog as t1 inner join OMIM_human_gene2disease_ensembl as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_ensembl` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_ensembl` ADD INDEX `disease` (`disease`);");


	$dbh->do("DROP TABLE IF EXISTS OMIM_${shortName}_gene2disease_ensembl_hdo;");
	$dbh->do("create TABLE OMIM_${shortName}_gene2disease_ensembl_hdo as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog as t1 inner join OMIM_human_gene2disease_ensembl_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_ensembl_hdo` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_ensembl_hdo` ADD INDEX `disease` (`disease`);");  

	##entrez
	$dbh->do("DROP TABLE IF EXISTS OMIM_${shortName}_gene2disease_entrez;");
	$dbh->do("create table OMIM_${shortName}_gene2disease_entrez as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog_entrez as t1 inner join OMIM_human_gene2disease_entrez as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_entrez` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_entrez` ADD INDEX `disease` (`disease`);");  

	$dbh->do("DROP TABLE IF EXISTS OMIM_${shortName}_gene2disease_entrez_hdo;");
	$dbh->do("create TABLE OMIM_${shortName}_gene2disease_entrez_hdo as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog_entrez as t1 inner join OMIM_human_gene2disease_entrez_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");  
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_entrez_hdo` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `OMIM_${shortName}_gene2disease_entrez_hdo` ADD INDEX `disease` (`disease`);");      	              
}  


##GeneRIF
foreach(@species_list){
	my $fullName=$_;
	my $shortName=$species_names{$fullName};
	
	$dbh->do("DROP TABLE IF EXISTS GeneRIF_${shortName}_gene2disease_ensembl;");
	$dbh->do("create table GeneRIF_${shortName}_gene2disease_ensembl as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog as t1 inner join GeneRIF_human_gene2disease_ensembl_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `GeneRIF_${shortName}_gene2disease_ensembl` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `GeneRIF_${shortName}_gene2disease_ensembl` ADD INDEX `disease` (`disease`);");   

	$dbh->do("DROP TABLE IF EXISTS GeneRIF_${shortName}_gene2disease_entrez;");
	$dbh->do("create table GeneRIF_${shortName}_gene2disease_entrez as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog_entrez as t1 inner join GeneRIF_human_gene2disease_entrez_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `GeneRIF_${shortName}_gene2disease_entrez` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `GeneRIF_${shortName}_gene2disease_entrez` ADD INDEX `disease` (`disease`);");                                	              
}  

##VARIATION
foreach(@species_list){
	my $fullName=$_;
	my $shortName=$species_names{$fullName};
	##ensembl
	$dbh->do("DROP TABLE IF EXISTS VARIATION_${shortName}_gene2disease_ensembl;");
	$dbh->do("create table VARIATION_${shortName}_gene2disease_ensembl as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog as t1 inner join VARIATION_human_gene2disease_ensembl as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_ensembl` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_ensembl` ADD INDEX `disease` (`disease`);");   


	$dbh->do("DROP TABLE IF EXISTS VARIATION_${shortName}_gene2disease_ensembl_hdo;");
	$dbh->do("create TABLE VARIATION_${shortName}_gene2disease_ensembl_hdo as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog as t1 inner join VARIATION_human_gene2disease_ensembl_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_ensembl_hdo` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_ensembl_hdo` ADD INDEX `disease` (`disease`);");   



	#entrez
	$dbh->do("DROP TABLE IF EXISTS VARIATION_${shortName}_gene2disease_entrez;");
	$dbh->do("create table VARIATION_${shortName}_gene2disease_entrez as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog_entrez as t1 inner join VARIATION_human_gene2disease_entrez as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_entrez` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_entrez` ADD INDEX `disease` (`disease`);");     

	$dbh->do("DROP TABLE IF EXISTS VARIATION_${shortName}_gene2disease_entrez_hdo;");
	$dbh->do("create TABLE VARIATION_${shortName}_gene2disease_entrez_hdo as
		select distinct homolog as gene,disease from ENSEMBL_human_homolog_entrez as t1 inner join VARIATION_human_gene2disease_entrez_hdo as t2
		on t1.human=t2.gene where t1.type='ortholog_one2one' and species='${shortName}';");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_entrez_hdo` ADD INDEX `gene` (`gene`);");
	$dbh->do("ALTER TABLE `VARIATION_${shortName}_gene2disease_entrez_hdo` ADD INDEX `disease` (`disease`);");  
                           	              
} 

##ALL
foreach(@species_list){
	my $fullName=$_;
	my $shortName=$species_names{$fullName};
	##ensembl
	$dbh->do("DROP TABLE IF EXISTS ALL_${shortName}_gene2disease_ensembl_hdo;");
	$dbh->do("Create table ALL_${shortName}_gene2disease_ensembl_hdo as 
		select t1.gene,t1.disease,GROUP_CONCAT(t1.source) as source,count(gene) as source_count from 
		(select *,'g' as source from GeneRIF_${shortName}_gene2disease_ensembl
		union all 
		select *,'o' as source from OMIM_${shortName}_gene2disease_ensembl_hdo
		union all
		select *,'v' as source from VARIATION_${shortName}_gene2disease_ensembl_hdo) as t1
		group by t1.gene,t1.disease;");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_ensembl_hdo` CHANGE  `source`  `source` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_ensembl_hdo` ADD INDEX (  `gene` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_ensembl_hdo` ADD INDEX (  `disease` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_ensembl_hdo` ADD INDEX (  `source` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_ensembl_hdo` ADD INDEX (  `source_count` );");   

	##entrez
	$dbh->do("DROP TABLE IF EXISTS ALL_${shortName}_gene2disease_entrez_hdo;");
	$dbh->do("Create table ALL_${shortName}_gene2disease_entrez_hdo as 
		select t1.gene,t1.disease,GROUP_CONCAT(t1.source) as source,count(gene) as source_count from 
		(select *,'g' as source from GeneRIF_${shortName}_gene2disease_entrez
		union all 
		select *,'o' as source from OMIM_${shortName}_gene2disease_entrez_hdo
		union all
		select *,'v' as source from VARIATION_${shortName}_gene2disease_entrez_hdo) as t1
		group by t1.gene,t1.disease;");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_entrez_hdo` CHANGE  `source`  `source` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_entrez_hdo` ADD INDEX (  `gene` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_entrez_hdo` ADD INDEX (  `disease` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_entrez_hdo` ADD INDEX (  `source` );");
	$dbh->do("ALTER TABLE  `ALL_${shortName}_gene2disease_entrez_hdo` ADD INDEX (  `source_count` );");  
} 



 
	
exit;

