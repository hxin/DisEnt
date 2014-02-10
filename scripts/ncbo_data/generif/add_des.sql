DROP TABLE IF EXISTS NCBO_rif2do;
create table NCBO_rif2do as 
select t1.source_id,t1.source,t1.do_acc,t2.name as do_description from NCBO_rif2do_raw as t1 left join DO_terms as t2
on t1.do_acc=t2.term_id;
ALTER TABLE  `NCBO_rif2do` ADD INDEX (  `source_id` );
ALTER TABLE  `NCBO_rif2do` ADD INDEX (  `do_acc` );
