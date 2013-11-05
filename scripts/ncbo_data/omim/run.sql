DROP TABLE IF EXISTS NCBO_omim2do_raw;
CREATE TABLE `NCBO_omim2do_raw` (
  `disorder_mim_acc` int(10) NOT NULL,
  `omim_description` text NOT NULL,
  `do_acc` varchar(15) DEFAULT NULL,
  `do_description` text,
  KEY `disorder_mim_acc` (`disorder_mim_acc`),
  KEY `do_acc` (`do_acc`)
) ENGINE=InnoDB;

