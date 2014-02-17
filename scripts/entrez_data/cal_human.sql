DROP table IF EXISTS human_gene;
create table human_gene as 
select distinct t1.entrez_id,t2.ensembl_id from ENTREZ_human_gene as t1 left join ENTREZ_entrez2ensembl as t2
on t1.entrez_id=t2.entrez_id;
ALTER TABLE `human_gene` ADD INDEX `entrez_id` (`entrez_id`);
ALTER TABLE `human_gene` ADD INDEX `ensembl_id`(`ensembl_id`);
