DROP TABLE IF EXISTS MetaMap_rif2do_raw;
CREATE TABLE `MetaMap_rif2do_raw` (
    `source_id` int(10) NOT NULL,
  `source_description` text NOT NULL,
  `do_acc` varchar(15) DEFAULT NULL,
  `do_description` text,
  `score` int(10) DEFAULT NULL,
  KEY `source_id` (`source_id`),
  KEY `do_acc` (`do_acc`),
  KEY `score` (`score`)
) ENGINE = INNODB;
