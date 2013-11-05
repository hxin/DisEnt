cat ./morbidmap| perl omim_d2g.pl >./OMIM_disease2gene.txt
mysql -h nrg.inf.ed.ac.uk -u xin -p12091209 -e 'TRUNCATE TABLE xin2.OMIM_disease2gene;'
mysqlimport -h nrg.inf.ed.ac.uk -u xin -p12091209 -c description,disorder_mim_acc,gene_symbol,locus_mim_acc,location -L ${DB} OMIM_disease2gene.txt
