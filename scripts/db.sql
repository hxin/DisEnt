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




