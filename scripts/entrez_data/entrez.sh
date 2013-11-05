BASEDIR=$(dirname $0)


if [ $USECACHE = 'n' ]; then
echo "getting entrez2ensembl mapping file from entrez FTP..."$(date +"%T")
wget -O $BASEDIR/tmp/gene2ensembl.gz ftp://ftp.ncbi.nih.gov/gene/DATA/gene2ensembl.gz
echo "Parsing entrez2ensembl mapping file..."$(date +"%T")
gzip -df $BASEDIR/tmp/gene2ensembl.gz
cut -f 1,2,3 $BASEDIR/tmp/gene2ensembl | tail -n+2>$BASEDIR/tmp/ENTREZ_entrez2ensembl
##yeast data missing...c_elegan also...
##need to think about how to get these data!!!
echo 'some of the mapping data is missing!! need to go back to this later to fix!!One way of doing it is using biomart ID mapping http://www.ensembl.org/biomart/...'$(date +"%T")
cat $BASEDIR/tmp/yeast_entrez2ensembl.txt|perl $BASEDIR/tmp/yeast_entrez2ensembl.pl >$BASEDIR/tmp/yeast_entrez2ensembl
cat $BASEDIR/tmp/yeast_entrez2ensembl>>$BASEDIR/tmp/ENTREZ_entrez2ensembl



echo "getting human_gene_entrez file from entrez FTP..."$(date +"%T")
wget -O $BASEDIR/tmp/Homo_sapiens.gene_info.gz ftp://ftp.ncbi.nih.gov/gene/DATA/GENE_INFO/Mammalia/Homo_sapiens.gene_info.gz
echo "Parsing geneinfo file..."$(date +"%T")
gzip -df $BASEDIR/tmp/Homo_sapiens.gene_info.gz
cut -f 2 $BASEDIR/tmp/Homo_sapiens.gene_info | tail -n+2>$BASEDIR/tmp/ENTREZ_human_gene
fi


echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/entrez.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -c tax_id,entrez_id,ensembl_id --ignore -L $DB $BASEDIR/tmp/ENTREZ_entrez2ensembl
mysqlimport -h $HOST -u $USER -p$PSW --delete --ignore -L $DB $BASEDIR/tmp/ENTREZ_human_gene
