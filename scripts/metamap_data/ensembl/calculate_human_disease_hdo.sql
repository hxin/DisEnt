DROP TABLE IF EXISTS VARIATION_human_gene2disease_ensembl_hdo;
create TABLE VARIATION_human_gene2disease_ensembl_hdo as
select distinct t1.gene,t2.do_acc as disease from VARIATION_human_gene2disease_ensembl as t1 inner join MetaMap_ensembl2do as t2
on t1.disease=t2.phenotype_id;

ALTER TABLE  `VARIATION_human_gene2disease_ensembl_hdo` ADD INDEX  (  `gene` );
ALTER TABLE  `VARIATION_human_gene2disease_ensembl_hdo` ADD INDEX  (  `disease` );

DROP TABLE IF EXISTS VARIATION_human_gene2disease_entrez_hdo;
create TABLE VARIATION_human_gene2disease_entrez_hdo as
select distinct t1.gene,t2.do_acc as disease from VARIATION_human_gene2disease_entrez as t1 inner join MetaMap_ensembl2do as t2
on t1.disease=t2.phenotype_id;

ALTER TABLE  `VARIATION_human_gene2disease_entrez_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `VARIATION_human_gene2disease_entrez_hdo` ADD INDEX (  `disease` );

