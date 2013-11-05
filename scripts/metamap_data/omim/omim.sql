DROP TABLE IF EXISTS MetaMap_omim2do_raw;
CREATE TABLE `MetaMap_omim2do_raw` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `disorder_mim_acc` int(10) NOT NULL,
  `omim_description` text NOT NULL,
  `do_acc_1` varchar(15) DEFAULT NULL,
  `do_description_1` text,
  `score_1` int(10) DEFAULT NULL,
  `do_acc_2` varchar(15) DEFAULT NULL,
  `do_description_2` text,
  `score_2` int(10) DEFAULT NULL,
  `do_acc_3` varchar(20) DEFAULT NULL,
  `do_description_3` text,
  `score_3` int(10) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `disorder_mim_acc` (`disorder_mim_acc`),
  KEY `do_acc_1` (`do_acc_1`),
  KEY `score_1` (`score_1`),
  KEY `do_acc_2` (`do_acc_2`),
  KEY `score_2` (`score_2`),
  KEY `do_acc_3` (`do_acc_3`),
  KEY `score_3` (`score_3`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS MetaMap_omim2do;
CREATE TABLE `MetaMap_omim2do` (
  `disorder_mim_acc` int(10) NOT NULL,
  `omim_description` text,
  `do_acc` varchar(15) DEFAULT NULL,
  `do_description` text,
  KEY `disorder_mim_acc` (`disorder_mim_acc`),
  KEY `do_acc` (`do_acc`)
) ENGINE=InnoDB;
