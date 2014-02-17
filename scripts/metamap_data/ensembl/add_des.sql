DROP TABLE IF EXISTS MetaMap_ensembl2do;
create table MetaMap_ensembl2do as 
select t1.source_id,t1.source_description,t1.do_acc,t2.name as do_description,t1.score from MetaMap_ensembl2do_raw as t1 left join DO_terms as t2
on t1.do_acc=t2.term_id;
ALTER TABLE  `MetaMap_ensembl2do` ADD INDEX (  `source_id` );
ALTER TABLE  `MetaMap_ensembl2do` ADD INDEX (  `do_acc` );
ALTER TABLE  `MetaMap_ensembl2do` ADD INDEX (  `score` );
