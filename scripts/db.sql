/**
ALL_ensembl2do
**/
DROP TABLE IF EXISTS ALL_ensembl2do;
CREATE TABLE `ALL_ensembl2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source from 
(
select t1.source_id,t1.source_description,t1.do_acc,t1.do_description,'M' as `mapping_source` from MetaMap_ensembl2do as t1 where t1.source_id !=0
union all
select t2.*,'N' as `mapping_source` from NCBO_ensembl2do as t2 where t2.source_id!=0 and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_ensembl2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `mapping_source` );

/**
ALL_omim2do
**/
DROP TABLE IF EXISTS ALL_omim2do;
CREATE TABLE `ALL_omim2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source from 
(
select t1.source_id,t1.source_description,t1.do_acc,t1.do_description,'M' as `mapping_source` from MetaMap_omim2do as t1 where t1.source_id !=0
union all
select t2.*,'N' as `mapping_source` from NCBO_omim2do as t2 where t2.source_id!=0  and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_omim2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `mapping_source` );

/**
ALL_rif2do
**/
DROP TABLE IF EXISTS ALL_rif2do;
CREATE TABLE `ALL_rif2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source from 
(
select t1.source_id,t1.source_description,t1.do_acc,t1.do_description,'M' as `mapping_source` from MetaMap_rif2do as t1 where t1.source_id !=0
union all
select t2.*,'N' as `mapping_source` from NCBO_rif2do as t2 where t2.source_id!=0  and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_rif2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `mapping_source` );

/**
Generif disease2gene
**/
DROP TABLE IF EXISTS GeneRIF_disease2gene;
create table GeneRIF_disease2gene as
select t2.gene_id as entrez_id,t2.pmid,t1.do_acc,t1.do_description,t1.source_description as rif 
from ALL_rif2do as t1 left join GeneRIF_basic as t2 on t1.source_id=t2.id;
ALTER TABLE `GeneRIF_disease2gene` ADD INDEX `entrez_id` (`entrez_id`);
ALTER TABLE `GeneRIF_disease2gene` ADD INDEX `pmid` (`pmid`);
ALTER TABLE `GeneRIF_disease2gene` ADD INDEX `do_acc` (`do_acc`);

/**
GeneRIF human entrez
**/
DROP TABLE IF EXISTS GeneRIF_human_gene2disease_entrez_hdo;
create table GeneRIF_human_gene2disease_entrez_hdo as
select distinct t1.entrez_id as gene,do_acc as disease from GeneRIF_disease2gene as t1 inner join ENTREZ_human_gene as t2 
on t1.entrez_id=t2.entrez_id;
ALTER TABLE `GeneRIF_human_gene2disease_entrez_hdo` ADD INDEX `gene` (`gene`);
ALTER TABLE `GeneRIF_human_gene2disease_entrez_hdo` ADD INDEX `disease` (`disease`);


/**
GeneRIF human ensembl
**/
DROP TABLE IF EXISTS GeneRIF_human_gene2disease_ensembl_hdo;
create table GeneRIF_human_gene2disease_ensembl_hdo as
select distinct ensembl_id as gene,disease from GeneRIF_human_gene2disease_entrez_hdo  as t1 left join ENTREZ_entrez2ensembl as t2
on t1.gene=t2.entrez_id where ensembl_id is not null ;
ALTER TABLE `GeneRIF_human_gene2disease_ensembl_hdo` ADD INDEX `gene` (`gene`);
ALTER TABLE `GeneRIF_human_gene2disease_ensembl_hdo` ADD INDEX `disease` (`disease`);


/**
omim uses entrez_id, here create a table for human gene2disease with entrez_id
**/
DROP TABLE IF EXISTS OMIM_human_gene2disease_entrez;
create table `OMIM_human_gene2disease_entrez` as 
select distinct t2.entrez_id as gene,disorder_mim_acc as disease from OMIM_disease2gene as t1 left join OMIM_mim2gene as t2
on t1.locus_mim_acc=t2.mim_acc where t1.disorder_mim_acc!=0 and t2.mim_acc!=0 and t2.entrez_id !=0;

ALTER TABLE `OMIM_human_gene2disease_entrez` ADD INDEX `gene` (`gene`);
ALTER TABLE `OMIM_human_gene2disease_entrez` ADD INDEX `disease` (`disease`);

/**
map the above table from entrez_id to ensembl_id
**/
DROP TABLE IF EXISTS OMIM_human_gene2disease_ensembl;
create table `OMIM_human_gene2disease_ensembl` as
select ensembl_id as gene,disease as disease from OMIM_human_gene2disease_entrez as t1 left join ENTREZ_entrez2ensembl as t2
on t1.gene=t2.entrez_id where ensembl_id is not null;
ALTER TABLE `OMIM_human_gene2disease_ensembl` ADD INDEX `gene` (`gene`);
ALTER TABLE `OMIM_human_gene2disease_ensembl` ADD INDEX `disease` (`disease`);


/**
VARIATION_human_gene2disease_ensembl
**/
DROP TABLE IF EXISTS VARIATION_human_gene2disease_ensembl;
create table VARIATION_human_gene2disease_ensembl as
SELECT distinct gene_id as gene,phenotype_id as disease FROM ENSEMBL_variation2phenotype as vp inner join ENSEMBL_variation2gene as vg
on vp.variation_id=vg.variation_id;
ALTER TABLE `VARIATION_human_gene2disease_ensembl` ADD INDEX `gene` (`gene`);
ALTER TABLE `VARIATION_human_gene2disease_ensembl` ADD INDEX `disease` (`disease`);
/**
map to entrez_id
**/
DROP TABLE IF EXISTS VARIATION_human_gene2disease_entrez;
create table VARIATION_human_gene2disease_entrez as
select distinct t2.entrez_id as gene,t1.disease from VARIATION_human_gene2disease_ensembl as t1 inner join ENTREZ_entrez2ensembl as t2
on t1.gene=t2.ensembl_id;
ALTER TABLE `VARIATION_human_gene2disease_entrez` ADD INDEX `gene` (`gene`);
ALTER TABLE `VARIATION_human_gene2disease_entrez` ADD INDEX `disease` (`disease`);








/**
OMIM map to HDO
**/

DROP TABLE IF EXISTS OMIM_human_gene2disease_ensembl_hdo;
create TABLE OMIM_human_gene2disease_ensembl_hdo as
select distinct t1.gene,t2.do_acc as disease from OMIM_human_gene2disease_ensembl as t1 inner join ALL_omim2do as t2
on t1.disease=t2.source_id;
ALTER TABLE  `OMIM_human_gene2disease_ensembl_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `OMIM_human_gene2disease_ensembl_hdo` ADD INDEX (  `disease` );


DROP TABLE IF EXISTS OMIM_human_gene2disease_entrez_hdo;
create TABLE OMIM_human_gene2disease_entrez_hdo as
select distinct t1.gene,t2.do_acc as disease from OMIM_human_gene2disease_entrez as t1 inner join ALL_omim2do as t2
on t1.disease=t2.source_id;
ALTER TABLE  `OMIM_human_gene2disease_entrez_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `OMIM_human_gene2disease_entrez_hdo` ADD INDEX (  `disease` );


/**
VARIATION map to HDO
**/
DROP TABLE IF EXISTS VARIATION_human_gene2disease_ensembl_hdo;
create TABLE VARIATION_human_gene2disease_ensembl_hdo as
select distinct t1.gene,t2.do_acc as disease from VARIATION_human_gene2disease_ensembl as t1 inner join ALL_ensembl2do as t2
on t1.disease=t2.source_id;

ALTER TABLE  `VARIATION_human_gene2disease_ensembl_hdo` ADD INDEX  (  `gene` );
ALTER TABLE  `VARIATION_human_gene2disease_ensembl_hdo` ADD INDEX  (  `disease` );

DROP TABLE IF EXISTS VARIATION_human_gene2disease_entrez_hdo;
create TABLE VARIATION_human_gene2disease_entrez_hdo as
select distinct t1.gene,t2.do_acc as disease from VARIATION_human_gene2disease_entrez as t1 inner join ALL_ensembl2do as t2
on t1.disease=t2.source_id;

ALTER TABLE  `VARIATION_human_gene2disease_entrez_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `VARIATION_human_gene2disease_entrez_hdo` ADD INDEX (  `disease` );






DROP TABLE IF EXISTS ALL_human_gene2disease_ensembl_hdo;
Create table ALL_human_gene2disease_ensembl_hdo as 
select t1.gene,t1.disease,GROUP_CONCAT(t1.source) as source,count(gene) as source_count from 
(select *,'g' as source from GeneRIF_human_gene2disease_ensembl_hdo
union all 
select *,'o' as source from OMIM_human_gene2disease_ensembl_hdo
union all
select *,'v' as source from VARIATION_human_gene2disease_ensembl_hdo) as t1
group by t1.gene,t1.disease;

ALTER TABLE  `ALL_human_gene2disease_ensembl_hdo` CHANGE  `source`  `source` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_human_gene2disease_ensembl_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `ALL_human_gene2disease_ensembl_hdo` ADD INDEX (  `disease` );
ALTER TABLE  `ALL_human_gene2disease_ensembl_hdo` ADD INDEX (  `source` );
ALTER TABLE  `ALL_human_gene2disease_ensembl_hdo` ADD INDEX (  `source_count` );

DROP TABLE IF EXISTS ALL_human_gene2disease_entrez_hdo;
Create table ALL_human_gene2disease_entrez_hdo as 
select t1.gene,t1.disease,GROUP_CONCAT(t1.source) as source,count(gene) as source_count from 
(select *,'g' as source from GeneRIF_human_gene2disease_entrez_hdo
union all 
select *,'o' as source from OMIM_human_gene2disease_entrez_hdo
union all
select *,'v' as source from VARIATION_human_gene2disease_entrez_hdo) as t1
group by t1.gene,t1.disease;

ALTER TABLE  `ALL_human_gene2disease_entrez_hdo` CHANGE  `source`  `source` VARCHAR( 20 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_human_gene2disease_entrez_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `ALL_human_gene2disease_entrez_hdo` ADD INDEX (  `disease` );
ALTER TABLE  `ALL_human_gene2disease_entrez_hdo` ADD INDEX (  `source` );
ALTER TABLE  `ALL_human_gene2disease_entrez_hdo` ADD INDEX (  `source_count` );




