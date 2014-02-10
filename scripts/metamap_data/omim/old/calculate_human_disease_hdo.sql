DROP TABLE IF EXISTS OMIM_human_gene2disease_ensembl_hdo;
create TABLE OMIM_human_gene2disease_ensembl_hdo as
select distinct t1.gene,t2.do_acc as disease from OMIM_human_gene2disease_ensembl as t1 inner join MetaMap_omim2do as t2
on t1.disease=t2.disorder_mim_acc;
ALTER TABLE  `OMIM_human_gene2disease_ensembl_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `OMIM_human_gene2disease_ensembl_hdo` ADD INDEX (  `disease` );


DROP TABLE IF EXISTS OMIM_human_gene2disease_entrez_hdo;
create TABLE OMIM_human_gene2disease_entrez_hdo as
select distinct t1.gene,t2.do_acc as disease from OMIM_human_gene2disease_entrez as t1 inner join MetaMap_omim2do as t2
on t1.disease=t2.disorder_mim_acc;
ALTER TABLE  `OMIM_human_gene2disease_entrez_hdo` ADD INDEX (  `gene` );
ALTER TABLE  `OMIM_human_gene2disease_entrez_hdo` ADD INDEX (  `disease` );
