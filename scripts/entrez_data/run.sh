BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi
NEED_UPDATE=n
ENTREZ2ENSEMBL=$BASEDIR/tmp/gene2ensembl.gz
ENTREZ2ENSEMBL_OLD=$BASEDIR/tmp/gene2ensembl.gz.old
ENTREZ_HUMAN_GENEINFO=$BASEDIR/tmp/Homo_sapiens.gene_info.gz
ENTREZ_HUMAN_GENEINFO_OLD=$BASEDIR/tmp/Homo_sapiens.gene_info.gz.old


if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Fetching entrez2ensembl mapping file from entrez FTP $ENTREZ2ENSEMBL_URL..."
	(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ2ENSEMBL_URL)
	if [ -e $ENTREZ2ENSEMBL_OLD ]; then
		##no need to update
        	if [ `md5sum $ENTREZ2ENSEMBL | cut -d ' ' -f 1` = `md5sum $ENTREZ2ENSEMBL_OLD | cut -d ' ' -f 1` ];then
			echo "[$(date +"%T %D")] You are using the lastest entrez2ensembl mapping data!"
		else 
			##overwrite backup file
			cp $ENTREZ2ENSEMBL $ENTREZ2ENSEMBL_OLD
			$NEED_UPDATE=y
		fi
	else 
		##make backup file
		cp $ENTREZ2ENSEMBL $ENTREZ2ENSEMBL_OLD
		$NEED_UPDATE=y
	fi

	echo "[$(date +"%T %D")] Fetching human gene_info from entrez FTP $ENTREZ_HUMAN_GENEINFO_URL..."
	(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ_HUMAN_GENEINFO_URL)
	if [ -e $ENTREZ_HUMAN_GENEINFO_OLD ]; then
		##no need to update
        	if [ `md5sum $ENTREZ2ENSEMBL | cut -d ' ' -f 1` = `md5sum $ENTREZ2ENSEMBL_OLD | cut -d ' ' -f 1` ];then
			echo "[$(date +"%T %D")] You are using the lastest entrez2ensembl mapping data!"
		else 
			$NEED_UPDATE=1
		fi
	else 
		##make backup file
		cp $ENTREZ2ENSEMBL $ENTREZ2ENSEMBL_OLD
		$NEED_UPDATE=1
	fi
	

fi

echo "getting human_gene_entrez file from entrez FTP..."$(date +"%T")
wget -O $BASEDIR/tmp/Homo_sapiens.gene_info.gz ftp://ftp.ncbi.nih.gov/gene/DATA/GENE_INFO/Mammalia/Homo_sapiens.gene_info.gz
echo "Parsing geneinfo file..."$(date +"%T")
gzip -df $BASEDIR/tmp/Homo_sapiens.gene_info.gz
cut -f 2 $BASEDIR/tmp/Homo_sapiens.gene_info | tail -n+2>$BASEDIR/tmp/ENTREZ_human_gene

if [ $NEED_UPDATE = 'y' ]; then
echo "[$(date +"%T %D")] Parsing entrez2ensembl mapping file..."
zcat $ENTREZ2ENSEMBL | cut -f 1,2,3 | tail -n+2 > $BASEDIR/tmp/ENTREZ_gene2ensembl

fi

exit;


##yeast data missing...c_elegan also...
##need to think about how to get these data!!!
echo 'some of the mapping data is missing!! need to go back to this later to fix!!One way of doing it is using biomart ID mapping http://www.ensembl.org/biomart/...'$(date +"%T")
cat $BASEDIR/tmp/yeast_entrez2ensembl.txt|perl $BASEDIR/tmp/yeast_entrez2ensembl.pl >$BASEDIR/tmp/yeast_entrez2ensembl
cat $BASEDIR/tmp/yeast_entrez2ensembl>>$BASEDIR/tmp/ENTREZ_entrez2ensembl



echo "getting entrez gene history..."
wget -O $BASEDIR/tmp/gene_history.gz ftp://ftp.ncbi.nlm.nih.gov/gene/DATA/gene_history.gz
zgrep "^9606" $BASEDIR/tmp/gene_history.gz > $BASEDIR/tmp/ENTREZ_gene_history

fi



echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/entrez.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -c tax_id,entrez_id,ensembl_id --ignore -L $DB $BASEDIR/tmp/ENTREZ_entrez2ensembl
mysqlimport -h $HOST -u $USER -p$PSW --delete --ignore -L $DB $BASEDIR/tmp/ENTREZ_human_gene
mysqlimport -h $HOST -u $USER -p$PSW --delete --ignore -L $DB $BASEDIR/tmp/ENTREZ_gene_history
