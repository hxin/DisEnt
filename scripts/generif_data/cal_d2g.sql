DROP table IF EXISTS DGA_d2g;
create table DGA_d2g as
select t1.entrez_id,t1.ensembl_id,t2.pmid,t2.do_acc as disease_id,0 as `did_type`,t2.rif from human_gene as t1 right join DGA as t2
on t1.entrez_id=t2.entrez_id;
ALTER TABLE `DGA_d2g` ADD INDEX (`entrez_id`);
ALTER TABLE `DGA_d2g` ADD INDEX (`ensembl_id`);
ALTER TABLE `DGA_d2g` ADD INDEX (`pmid`);
ALTER TABLE `DGA_d2g` ADD INDEX  (`did_type`);
ALTER TABLE `DGA_d2g` ADD INDEX  (`disease_id`);


#create table GeneRIF_d2g as
#select t1.ensembl_id,t2.* from human_gene as t1 right join DGA as t2
#on t1.entrez_id=t2.entrez_id;
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `ensembl_id` (`ensembl_id`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `entrez_id` (`entrez_id`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `pmid` (`pmid`);
#ALTER TABLE `GeneRIF_d2g` ADD INDEX `do_acc` (`do_acc`);
