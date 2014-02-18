#DROP TABLE IF EXISTS GeneRIF_basic;
CREATE TABLE IF NOT EXISTS `GeneRIF_basic` (
`id` INT( 11 ) NOT NULL AUTO_INCREMENT ,
 `gene_id` INT( 50 ) NOT NULL ,
 `pmid` INT( 50 ) NOT NULL ,
 `rif` TEXT NOT NULL ,
PRIMARY KEY (  `id` ) ,
KEY  `pmid` (  `pmid` ) ,
KEY  `gene_id` (  `gene_id` )
);

DROP TABLE IF EXISTS DGA;
CREATE TABLE IF NOT EXISTS `DGA` (
  `entrez_id` int(11) DEFAULT NULL,
/*  `pmed_title` text,*/
  `pmid` int(11) DEFAULT NULL,
/*  `umls_acc` varchar(64) DEFAULT NULL,*/
  `do_acc` varchar(64) DEFAULT NULL,
  `rif` text,
/*  `unknown_acc` int(11) DEFAULT NULL,*/
  KEY `entrez_id` (`entrez_id`),
  KEY `pmid` (`pmid`),
/*  KEY `umls_acc` (`umls_acc`),*/
  KEY `do_acc` (`do_acc`)
/*  KEY `unknown_acc` (`unknown_acc`)*/
);





