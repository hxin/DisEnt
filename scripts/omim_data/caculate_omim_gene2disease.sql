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


