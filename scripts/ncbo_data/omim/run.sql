DROP TABLE IF EXISTS NCBO_omim2do_raw;
CREATE TABLE `NCBO_omim2do_raw` (
  `source_id` int(10) NOT NULL,
  `source_description` text NOT NULL,
  `do_acc` varchar(15) DEFAULT NULL,
  `do_description` text NOT NULL,
  KEY `source_id` (`source_id`),
  KEY `do_acc` (`do_acc`)
) ENGINE=InnoDB;

