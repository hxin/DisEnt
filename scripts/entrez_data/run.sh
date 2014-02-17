BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

E2E=$BASEDIR/tmp/gene2ensembl.gz
H_GENEINFO=$BASEDIR/tmp/Homo_sapiens.gene_info.gz
GENE_HISTORY=$BASEDIR/tmp/gene_history.gz


if [ $USECACHE = 'n' ]; then

	echo "[$(date +"%T %D")] Checking update for entrez2ensembl mapping data..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $ENTREZ2ENSEMBL_URL 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $ENTREZ2ENSEMBL_URL..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ2ENSEMBL_URL)
		chmod 664 $E2E
		echo "[$(date +"%T %D")] Parsing ..."
		zcat $E2E | cut -f 1,2,3 | tail -n+2 > $BASEDIR/tmp/ENTREZ_entrez2ensembl
	fi

	echo "[$(date +"%T %D")] Checking update for human_geneinfo data..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $ENTREZ_HUMAN_GENEINFO_URL 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $H_GENEINFO..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ_HUMAN_GENEINFO_URL)
		chmod 664 $H_GENEINFO
		echo "[$(date +"%T %D")] Parsing..."
		zcat $H_GENEINFO | cut -f 2 | tail -n+2 > $BASEDIR/tmp/ENTREZ_human_gene
	fi

	echo "[$(date +"%T %D")] Checking update for gene history data..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $ENTREZ_GENE_HISTORY_URL 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $ENTREZ_GENE_HISTORY_URL..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $ENTREZ_GENE_HISTORY_URL)
		chmod 664 $GENE_HISTORY
		echo "[$(date +"%T %D")] Parsing..."
		zgrep "^9606" $GENE_HISTORY > $BASEDIR/tmp/ENTREZ_gene_history
	fi
fi



if [ $NEED_UPDATE_DB -eq 1 ]; then
echo "[$(date +"%T %D")] Updating db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -c tax_id,entrez_id,ensembl_id --ignore -L $DB $BASEDIR/tmp/ENTREZ_entrez2ensembl
mysqlimport -h $HOST -u $USER -p$PSW --delete --ignore -L $DB $BASEDIR/tmp/ENTREZ_human_gene
mysqlimport -h $HOST -u $USER -p$PSW --delete --ignore -L $DB $BASEDIR/tmp/ENTREZ_gene_history
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/cal_human.sql
fi


exit 0;


##yeast data missing...c_elegan also...
##need to think about how to get these data!!!
echo 'some of the mapping data is missing!! need to go back to this later to fix!!One way of doing it is using biomart ID mapping http://www.ensembl.org/biomart/...'$(date +"%T")
cat $BASEDIR/tmp/yeast_entrez2ensembl.txt|perl $BASEDIR/tmp/yeast_entrez2ensembl.pl >$BASEDIR/tmp/yeast_entrez2ensembl
cat $BASEDIR/tmp/yeast_entrez2ensembl>>$BASEDIR/tmp/ENTREZ_entrez2ensembl






