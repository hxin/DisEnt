CREATE TABLE IF NOT EXISTS `NCBO_rif2do_raw` (
 `source_id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
 `source` text NOT NULL,
 `do_acc` VARCHAR( 50 ) NOT NULL ,
 `do_description` text NOT NULL ,
KEY  `source_id` (  `source_id` ) ,
KEY  `do_acc` (  `do_acc` )
) ENGINE = INNODB;
