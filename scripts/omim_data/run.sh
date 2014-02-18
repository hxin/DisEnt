BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

M2G=$BASEDIR/tmp/mim2gene.txt
MORBIDMAP=$BASEDIR/tmp/morbidmap
D2G=$BASEDIR/tmp/OMIM_disease2gene
[ ! -d $BASEDIR/tmp ] && mkdir $BASEDIR/tmp;
if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Checking update..."
	([ -z "$(cd $BASEDIR/tmp/; wget -N --spider $MIM2GENE_URL 2>&1 | grep 'exists')" ] && [ -z "$(cd $BASEDIR/tmp/; wget -N --spider $MORBIDMAP_URL 2>&1 | grep 'exists')" ] && exit 0; exit 1; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $MIM2GENE_URL..." 
		echo "[$(date +"%T %D")] Fetching from $MORBIDMAP_URL..." 
		(cd $BASEDIR/tmp/; wget -nv -N $MIM2GENE_URL)
		(cd $BASEDIR/tmp/; wget -nv -N $MORBIDMAP_URL)
		chmod 664 $MORBIDMAP
		chmod 664 $M2G
		echo "[$(date +"%T %D")] Parsing ..."
		cat $M2G | tail -n+2 > $BASEDIR/tmp/OMIM_mim2gene.txt
	fi
fi

if [ $NEED_UPDATE_DB -eq 1 ]; then
	echo "[$(date +"%T %D")] Updating db..."$(date +"%T")
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
	mysqlimport -h $HOST -u $USER -p$PSW -c mim_acc,type,entrez_id,gene_symbol -L $DB $BASEDIR/tmp/OMIM_mim2gene.txt	
	perl $BASEDIR/omim_d2g.pl $DB $HOST $USER $PSW $MORBIDMAP > $D2G
	mysqlimport -h $HOST -u $USER -p$PSW -c description,disorder_mim_acc,gene_symbol,locus_mim_acc,location -L $DB $D2G
fi


exit 0;

#create two table base on the ftp file
if [ $USECACHE = 'n' ]; then
wget -O $BASEDIR/tmp/mim2gene.txt ftp://anonymous:xin.he%40ed.ac.uk@grcf.jhmi.edu/OMIM/mim2gene.txt
wget -O $BASEDIR/tmp/morbidmap.txt ftp://grcf.jhmi.edu/OMIM/morbidmap
fi


#create db tables
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/omim.sql

#disease2gene
echo 'Parsing omim raw file...'$(date +"%T")
perl $BASEDIR/disease2gene/omim_d2g.pl $DB $HOST $USER $PSW $BASEDIR/tmp/morbidmap > $BASEDIR/tmp/OMIM_disease2gene.txt

mysqlimport -h $HOST -u $USER -p$PSW -c description,disorder_mim_acc,gene_symbol,locus_mim_acc,location -L $DB $BASEDIR/tmp/OMIM_disease2gene.txt
#mim2gene

#sed -e 's/\t-/ /g' $BASEDIR/tmp/mim2gene.txt | tail -n+2 > $BASEDIR/tmp/OMIM_mim2gene.txt
cat $BASEDIR/tmp/mim2gene.txt | tail -n+2 > $BASEDIR/tmp/OMIM_mim2gene.txt

echo 'inserting into db...'$(date +"%T")
mysqlimport -h $HOST -u $USER -p$PSW -c mim_acc,type,entrez_id,gene_symbol -L $DB $BASEDIR/tmp/OMIM_mim2gene.txt


#echo "caculating omim_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_omim_gene2disease.sql
