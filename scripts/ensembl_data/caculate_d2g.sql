DROP table IF EXISTS ENSEMBL_d2g;
create table ENSEMBL_d2g as 
select t4.entrez_id,t3.ensembl_id,t3.disease_id,t3.did_type from 
(SELECT distinct gene_id as ensembl_id, phenotype_id as disease_id, '1' as `did_type` FROM ENSEMBL_v2p as vp inner join 
(select t1.*,t2.entrez_id from ENSEMBL_v2g as t1 left join ENTREZ_entrez2ensembl as t2 on t1.gene_id=t2.ensembl_id) as vg
on vp.variation_id=vg.variation_id) as t3 left join ENTREZ_entrez2ensembl as t4 on t3.ensembl_id=t4.ensembl_id;

ALTER TABLE `ENSEMBL_d2g` ADD INDEX `gid_type` (`entrez_id`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `did_type` (`ensembl_id`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `gene_id` (`did_type`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `disease_id` (`disease_id`);



