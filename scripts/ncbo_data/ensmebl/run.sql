DROP TABLE IF EXISTS NCBO_ensembl2do_raw;
CREATE TABLE `NCBO_ensembl2do_raw` (
  `phenotype_id` int(10) NOT NULL,
  `phenotype_description` text NOT NULL,
  `do_acc` varchar(15) DEFAULT NULL,
  `do_description` text,
  KEY `phenotype_id` (`phenotype_id`),
  KEY `do_acc` (`do_acc`)
) ENGINE=InnoDB;

