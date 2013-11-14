DROP TABLE IF EXISTS ALL_ensembl2do;
CREATE TABLE `ALL_ensembl2do` as 
select t3.phenotype_id,phenotype_description,t3.do_acc,t3.do_description, group_concat(source) as source from 
(
select t1.phenotype_id,t1.phenotype_description,t1.do_acc,t1.do_description,'M' as `source` from MetaMap_ensembl2do_raw as t1 where t1.phenotype_id !=0
union all
select t2.*,'N' as `source` from NCBO_ensembl2do_raw as t2 where t2.phenotype_id!=0 and t2.do_acc is not null)
as t3  group by t3.phenotype_id,phenotype_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_ensembl2do` CHANGE  `source`  `source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `phenotype_id` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `source` );
