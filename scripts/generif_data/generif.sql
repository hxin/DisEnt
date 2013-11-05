DROP TABLE IF EXISTS GeneRIF_disease2gene;
CREATE TABLE `GeneRIF_disease2gene` (
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
) ENGINE=MyISAM 
