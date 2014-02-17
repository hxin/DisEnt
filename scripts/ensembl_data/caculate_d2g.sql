DROP table IF EXISTS ENSEMBL_d2g;
create table ENSEMBL_d2g as 
SELECT distinct gene_id as gene_id, '1' as `gid_type`, phenotype_id as dis_id, '1' as `did_type` FROM ENSEMBL_v2p as vp inner join (select t1.*,t2.entrez_id from ENSEMBL_v2g as t1 left join ENTREZ_entrez2ensembl as t2 on t1.gene_id=t2.ensembl_id) as vg
on vp.variation_id=vg.variation_id
union all
SELECT distinct entrez_id as gene_id, '0' as `gid_type`, '1' as `did_type`, phenotype_id as dis_id FROM ENSEMBL_v2p as vp inner join (select t1.*,t2.entrez_id from ENSEMBL_v2g as t1 left join ENTREZ_entrez2ensembl as t2 on t1.gene_id=t2.ensembl_id) as vg
on vp.variation_id=vg.variation_id;

ALTER TABLE `ENSEMBL_d2g` ADD INDEX `gid_type` (`gid_type`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `did_type` (`did_type`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `gene_id` (`gene_id`);
ALTER TABLE `ENSEMBL_d2g` ADD INDEX `dis_id` (`dis_id`);

