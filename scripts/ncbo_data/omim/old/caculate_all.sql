DROP TABLE IF EXISTS ALL_omim2do;
CREATE TABLE `ALL_omim2do` as 
select t3.disorder_mim_acc,omim_description,t3.do_acc,t3.do_description, group_concat(source) as source from 
(
select t1.*,'M' as `source` from MetaMap_omim2do as t1 where t1.disorder_mim_acc !=0
union all
select t2.*,'N' as `source` from NCBO_omim2do_raw as t2 where t2.disorder_mim_acc!=0  and t2.do_acc is not null)
as t3  group by t3.disorder_mim_acc,omim_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_omim2do` CHANGE  `source`  `source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `disorder_mim_acc` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `source` );
