DROP TABLE IF EXISTS ENSEMBL_human_homolog;  
CREATE TABLE `ENSEMBL_human_homolog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `human` varchar(30) NOT NULL,
  `homolog` varchar(50) NOT NULL,
  `dn_ds` float DEFAULT NULL,
  `type` varchar(30) NOT NULL,
  `species` varchar(30) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `human` (`human`),
  KEY `homolog` (`homolog`),
  KEY `dn_ds` (`dn_ds`),
  KEY `type` (`type`),
  KEY `species` (`species`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS ENSEMBL_human_gene;  
CREATE TABLE `ENSEMBL_human_gene` (
  `ensembl_id` varchar(30) NOT NULL,
  `chr` varchar(45) NOT NULL,
  `start` int(20) NOT NULL,
  `end` int(20) NOT NULL,
  PRIMARY KEY (`ensembl_id`),
KEY `chr` (`chr`),
KEY `start` (`start`),
KEY `end` (`end`)
) ENGINE=InnoDB;


DROP TABLE IF EXISTS ENSEMBL_variation; 
CREATE TABLE `ENSEMBL_variation` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `variation_id` varchar(45) NOT NULL,
  `chr` varchar(45) NOT NULL,
  `start` int(20) NOT NULL,
  `end` int(20) NOT NULL,
  PRIMARY KEY (`id`),
UNIQUE KEY `join_unique_1` (`variation_id` ,  `chr` ,  `start` ,  `end`),
  KEY `variation_id` (`variation_id`),
KEY `chr` (`chr`),
KEY `start` (`start`),
KEY `end` (`end`)
) ENGINE=InnoDB;



DROP TABLE IF EXISTS ENSEMBL_variation2phenotype;
CREATE TABLE `ENSEMBL_variation2phenotype` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `variation_id` varchar(20) DEFAULT NULL,
  `phenotype_source` varchar(20) DEFAULT NULL,
  `phenotype_source_id` varchar(20) DEFAULT NULL,
  `phenotype_id` int(10) DEFAULT NULL,
  `phenotype_description` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `join_unique_1` (`variation_id`,`phenotype_source`,`phenotype_source_id`,`phenotype_id`),
  KEY `phenotype_id` (`phenotype_id`),
  KEY `phenotype_source_id` (`phenotype_source_id`),
  KEY `variation_id` (`variation_id`),
  KEY `phenotype_source` (`phenotype_source`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ENSEMBL_variation2gene;
CREATE TABLE `ENSEMBL_variation2gene` (
  `variation_id` varchar(45) NOT NULL,
  `gene_id` varchar(45) NOT NULL,
  `position` varchar(20) NOT NULL,
  KEY `variation_id` (`variation_id`),
KEY `position` (`position`),
  KEY `gene_id` (`gene_id`)
) ENGINE=InnoDB








