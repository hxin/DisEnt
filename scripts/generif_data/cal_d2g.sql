
DROP table IF EXISTS GeneRIF_d2g;
create table GeneRIF_d2g as
select t1.ensembl_id as gene_id, 1 as `gid_type`,t2.pmid,t2.do_acc as dis_id,0 as `did_type`,t2.rif from human_gene as t1 right join GeneRIF_dga as t2
on t1.entrez_id=t2.entrez_id where ensembl_id is not null
union all 
select t1.entrez_id as gene_id, 0 as `gid_type`,t2.pmid,t2.do_acc as dis_id,0 as `did_type`,t2.rif from human_gene as t1 right join GeneRIF_dga as t2
on t1.entrez_id=t2.entrez_id;
ALTER TABLE `GeneRIF_d2g` ADD INDEX `gid_type` (`gid_type`);
ALTER TABLE `GeneRIF_d2g` ADD INDEX `did_type` (`did_type`);
ALTER TABLE `GeneRIF_d2g` ADD INDEX `gene_id` (`gene_id`);
ALTER TABLE `GeneRIF_d2g` ADD INDEX `pmid` (`pmid`);
ALTER TABLE `GeneRIF_d2g` ADD INDEX `dis_id` (`dis_id`);


#create table GeneRIF_d2g as
#select t1.ensembl_id,t2.* from human_gene as t1 right join GeneRIF_dga as t2
#on t1.entrez_id=t2.entrez_id;
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `ensembl_id` (`ensembl_id`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `entrez_id` (`entrez_id`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `pmid` (`pmid`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `do_acc` (`do_acc`);
