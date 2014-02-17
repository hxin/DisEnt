DROP TABLE IF EXISTS ENTREZ_entrez2ensembl; 
CREATE TABLE `ENTREZ_entrez2ensembl` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tax_id` int(10) NOT NULL,
  `entrez_id` int(20) NOT NULL,
  `ensembl_id` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `entrez_id_2` (`entrez_id`,`ensembl_id`),
  KEY `tax_id` (`tax_id`),
  KEY `entrez_id` (`entrez_id`),
  KEY `ensembl_id` (`ensembl_id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ENTREZ_human_gene; 
CREATE TABLE `ENTREZ_human_gene` (
  `entrez_id` int(30) NOT NULL,
  PRIMARY KEY (`entrez_id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS ENTREZ_gene_history; 
CREATE TABLE `ENTREZ_gene_history` (
  `tax_id` int(30) NOT NULL,
`gene_id` int(30) NOT NULL,
`discontinued_id` int(30) NOT NULL,
`discontinued_symbol` varchar(30) NOT NULL,
`discontinued_date` varchar(30) NOT NULL,
KEY `tax_id` (`tax_id`),
KEY `gene_id` (`gene_id`),
KEY `discontinued_id` (`discontinued_id`),
KEY `discontinued_symbol` (`discontinued_symbol`),
KEY `discontinued_date` (`discontinued_date`)
) ENGINE=InnoDB;
