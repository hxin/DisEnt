DROP TABLE IF EXISTS OMIM_mim2gene;
CREATE TABLE `OMIM_mim2gene` (
  `mim_acc` int(11) NOT NULL,
  `type` varchar(64) DEFAULT NULL,
  `entrez_id` int(11) DEFAULT NULL,
  `gene_symbol` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`mim_acc`),
  KEY `type` (`type`),
  KEY `entrez_id` (`entrez_id`),
  KEY `gene_symbol` (`gene_symbol`)
) ENGINE=MyISAM;


DROP TABLE IF EXISTS OMIM_disease2gene;
CREATE TABLE `OMIM_disease2gene` (
  `locus_mim_acc` int(11) DEFAULT NULL,
  `disorder_mim_acc` int(11) DEFAULT NULL,
  `description` text,
  `gene_symbol` varchar(64) DEFAULT NULL,
  `location` varchar(20) DEFAULT NULL,
  KEY `locus_mim_acc` (`locus_mim_acc`),
  KEY `disorder_mim_acc` (`disorder_mim_acc`),
  KEY `gene_symbol` (`gene_symbol`)
) ENGINE=MyISAM;
