DROP TABLE IF EXISTS ENSEMBL_human_homolog_entrez; 
create table ENSEMBL_human_homolog_entrez as
select t3.human,t4.entrez_id as homolog,t3.dn_ds,t3.type,t3.species from
(select entrez_id as human,t1.homolog,t1.dn_ds,t1.type,t1.species from ENSEMBL_human_homolog as t1 inner join ENTREZ_entrez2ensembl as t2 
on t1.human=t2.ensembl_id) as t3 inner join ENTREZ_entrez2ensembl as t4 
on t3.homolog=t4.ensembl_id;
ALTER TABLE `ENSEMBL_human_homolog_entrez` ADD INDEX `human` (`human`);
ALTER TABLE `ENSEMBL_human_homolog_entrez` ADD INDEX `homolog` (`homolog`);
ALTER TABLE `ENSEMBL_human_homolog_entrez` ADD INDEX `dn_ds` (`dn_ds`);
ALTER TABLE `ENSEMBL_human_homolog_entrez` ADD INDEX `type` (`type`);
ALTER TABLE `ENSEMBL_human_homolog_entrez` ADD INDEX `species` (`species`);

