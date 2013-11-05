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
