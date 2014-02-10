DROP TABLE IF EXISTS MetaMap_omim2do_raw_tmp;
RENAME TABLE MetaMap_omim2do_raw TO MetaMap_omim2do_raw_tmp;
create table MetaMap_omim2do_raw as 
select disorder_mim_acc,omim_description,do_acc,do_description,score from (
SELECT disorder_mim_acc,omim_description,do_acc_1 as do_acc,do_description_1 as do_description, score_1 as score FROM MetaMap_omim2do_raw_tmp where do_acc_1 is not null
union all
SELECT disorder_mim_acc,omim_description,do_acc_2 as do_acc,do_description_2 as do_description, score_2 as score FROM MetaMap_omim2do_raw_tmp where do_acc_2 is not null
union all 
SELECT disorder_mim_acc,omim_description,do_acc_3 as do_acc,do_description_3 as do_description, score_3 as score FROM MetaMap_omim2do_raw_tmp where do_acc_3 is not null
) as t1;
DROP TABLE IF EXISTS MetaMap_omim2do_raw_tmp;
ALTER TABLE  `MetaMap_omim2do_raw` ADD INDEX  (  `disorder_mim_acc` );
ALTER TABLE  `MetaMap_omim2do_raw` ADD INDEX  (  `do_acc` );
ALTER TABLE  `MetaMap_omim2do_raw` ADD INDEX  (  `score` );

