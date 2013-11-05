DROP TABLE IF EXISTS VARIATION_human_gene2disease_ensembl;
create table VARIATION_human_gene2disease_ensembl as
SELECT distinct gene_id as gene,phenotype_id as disease FROM ENSEMBL_variation2phenotype as vp inner join ENSEMBL_variation2gene as vg
on vp.variation_id=vg.variation_id;
ALTER TABLE `VARIATION_human_gene2disease_ensembl` ADD INDEX `gene` (`gene`);
ALTER TABLE `VARIATION_human_gene2disease_ensembl` ADD INDEX `disease` (`disease`);

DROP TABLE IF EXISTS VARIATION_human_gene2disease_entrez;
create table VARIATION_human_gene2disease_entrez as
select distinct t2.entrez_id as gene,t1.disease from VARIATION_human_gene2disease_ensembl as t1 inner join ENTREZ_entrez2ensembl as t2
on t1.gene=t2.ensembl_id;
ALTER TABLE `VARIATION_human_gene2disease_entrez` ADD INDEX `gene` (`gene`);
ALTER TABLE `VARIATION_human_gene2disease_entrez` ADD INDEX `disease` (`disease`);


