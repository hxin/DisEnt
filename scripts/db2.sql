/**
ALL_ensembl2do
**/
DROP TABLE IF EXISTS ALL_ensembl2do;
CREATE TABLE `ALL_ensembl2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source, group_concat(score) as score from 
(
select t1.source_id,t1.source_description,t1.do_acc,t1.do_description,'M' as `mapping_source`,t1.score from MetaMap_ensembl2do as t1 where t1.source_id !=0
union all
select t2.*,'N' as `mapping_source`, null as `score` from NCBO_ensembl2do as t2 where t2.source_id!=0 and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_ensembl2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_ensembl2do` ADD INDEX (  `mapping_source` );


/**
ALL_omim2do
**/
DROP TABLE IF EXISTS ALL_omim2do;
CREATE TABLE `ALL_omim2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source, group_concat(score) as score from 
(
select t1.*,'M' as `mapping_source` from MetaMap_omim2do as t1 where t1.source_id !=0
union all
select t2.*,null as `score`,'N' as `mapping_source` from NCBO_omim2do as t2 where t2.source_id!=0  and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_omim2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_omim2do` ADD INDEX (  `mapping_source` );

/**
ALL_rif2do

DROP TABLE IF EXISTS ALL_rif2do;
CREATE TABLE `ALL_rif2do` as 
select t3.source_id,source_description,t3.do_acc,t3.do_description, group_concat(mapping_source) as mapping_source,group_concat(score) as score from 
(
select t1.*,'M' as `mapping_source` from MetaMap_rif2do as t1 where t1.source_id !=0
union all
select t2.*,null as `score` ,'N' as `mapping_source` from NCBO_rif2do as t2 where t2.source_id!=0  and t2.do_acc is not null)
as t3  group by t3.source_id,source_description,t3.do_acc,do_description;

ALTER TABLE  `ALL_rif2do` CHANGE  `mapping_source`  `mapping_source` VARCHAR( 200 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL;
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `source_id` );
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `ALL_rif2do` ADD INDEX (  `mapping_source` );
**/



DROP TABLE IF EXISTS __tmp_human_d2g_generif;
CREATE TABLE `__tmp_human_d2g_generif` as
SELECT distinct t1.entrez_id,t1.ensembl_id,t1.disease_id,t1.did_type ,'g' as `db` FROM DGA_d2g as t1;
ALTER TABLE  `__tmp_human_d2g_generif` ADD INDEX (  `entrez_id` );
ALTER TABLE  `__tmp_human_d2g_generif` ADD INDEX (  `ensembl_id` );
ALTER TABLE  `__tmp_human_d2g_generif` ADD INDEX (  `disease_id` );
ALTER TABLE  `__tmp_human_d2g_generif` ADD INDEX (  `did_type` );
ALTER TABLE  `__tmp_human_d2g_generif` ADD INDEX (  `db` );


DROP TABLE IF EXISTS __tmp_human_d2g_omim;
CREATE TABLE `__tmp_human_d2g_omim` as
select * from 
(select t3.entrez_id, t4.ensembl_id, t3.disease_id,t3.did_type,t3.db from 
(select distinct t2.entrez_id,disorder_mim_acc as disease_id, '2' as did_type, 'o' as `db` from OMIM_disease2gene as t1 left join OMIM_mim2gene as t2
on t1.locus_mim_acc=t2.mim_acc where t1.disorder_mim_acc!=0 and t2.mim_acc!=0 and t2.entrez_id !=0) as t3 left join ENTREZ_entrez2ensembl as t4
on t3.entrez_id=t4.entrez_id) as t5 left join ALL_omim2do as t6
on t5.disease_id=t6.source_id;
ALTER TABLE  `__tmp_human_d2g_omim` ADD INDEX (  `entrez_id` );
ALTER TABLE  `__tmp_human_d2g_omim` ADD INDEX (  `ensembl_id` );
ALTER TABLE  `__tmp_human_d2g_omim` ADD INDEX (  `disease_id` );
ALTER TABLE  `__tmp_human_d2g_omim` ADD INDEX (  `did_type` );
ALTER TABLE  `__tmp_human_d2g_omim` ADD INDEX (  `db` );



DROP TABLE IF EXISTS __tmp_human_d2g_variation;
CREATE TABLE `__tmp_human_d2g_variation` as
select *,'v' as db from ENSEMBL_d2g as t1 left join ALL_ensembl2do as t2
on t1.disease_id=t2.source_id;
ALTER TABLE  `__tmp_human_d2g_variation` ADD INDEX (  `entrez_id` );
ALTER TABLE  `__tmp_human_d2g_variation` ADD INDEX (  `ensembl_id` );
ALTER TABLE  `__tmp_human_d2g_variation` ADD INDEX (  `disease_id` );
ALTER TABLE  `__tmp_human_d2g_variation` ADD INDEX (  `did_type` );
ALTER TABLE  `__tmp_human_d2g_variation` ADD INDEX (  `db` );

DROP TABLE IF EXISTS human_d2g;
CREATE TABLE `human_d2g` as 
select * from __tmp_human_d2g_generif
union
(select entrez_id,ensembl_id,disease_id,did_type,db from __tmp_human_d2g_omim)
UNION
(select entrez_id,ensembl_id,do_acc as disease_id,0 as `did_type`,db from __tmp_human_d2g_omim where do_acc is not null)
union
(select entrez_id,ensembl_id,disease_id,did_type,db from __tmp_human_d2g_variation)
union 
(select entrez_id,ensembl_id,do_acc as disease_id,0 as `did_type`,db from __tmp_human_d2g_variation where do_acc is not null)
;
ALTER TABLE  `human_d2g` ADD INDEX (  `entrez_id` );
ALTER TABLE  `human_d2g` ADD INDEX (  `ensembl_id` );
ALTER TABLE  `human_d2g` ADD INDEX (  `disease_id` );
ALTER TABLE  `human_d2g` ADD INDEX (  `did_type` );
ALTER TABLE  `human_d2g` ADD INDEX (  `db` );

DROP TABLE IF EXISTS __tmp_human_d2g_generif;
DROP TABLE IF EXISTS __tmp_human_d2g_omim;
DROP TABLE IF EXISTS __tmp_human_d2g_variation;



