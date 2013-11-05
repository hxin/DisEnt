DROP TABLE IF EXISTS GeneRIF_NCBO_disease2gene;
CREATE TABLE  `GeneRIF_NCBO_disease2gene` (
 `rif_id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
 `gene_id` INT( 50 ) NOT NULL ,
 `do_acc` VARCHAR( 50 ) NOT NULL ,
KEY  `rif_id` (  `rif_id` ) ,
KEY  `do_acc` (  `do_acc` ) ,
KEY  `gene_id` (  `gene_id` )
) ENGINE = INNODB;
