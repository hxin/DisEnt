DROP TABLE IF EXISTS GeneRIF_basic;
CREATE TABLE  `GeneRIF_basic` (
`id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
 `gene_id` INT( 50 ) NOT NULL ,
 `pmid` INT( 50 ) NOT NULL ,
 `rif` TEXT NOT NULL ,
PRIMARY KEY (  `id` ) ,
KEY  `pmid` (  `pmid` ) ,
KEY  `gene_id` (  `gene_id` )
) ENGINE = INNODB;



DROP TABLE IF EXISTS GeneRIF_MetaMap_disease2gene;
CREATE TABLE  `GeneRIF_MetaMap_disease2gene` (
 `rif_id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
 `gene_id` INT( 50 ) NOT NULL ,
 `do_acc` VARCHAR( 50 ) NOT NULL ,
 `score` INT( 10 ) NOT NULL ,
KEY  `rif_id` (  `rif_id` ) ,
KEY  `do_acc` (  `do_acc` ) ,
KEY  `score` (  `score` ) ,
KEY  `gene_id` (  `gene_id` )
) ENGINE = INNODB;
