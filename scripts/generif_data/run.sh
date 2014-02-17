BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

GRIFB=$BASEDIR/tmp/generifs_basic.gz
DGA=$BASEDIR/tmp/IDMappings.rdf

if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Checking update for Generif data..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -N --spider $GENERIF_BASIC_URL 2>&1 | grep 'exists')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	if [ $? -eq 0 ];then
		echo "[$(date +"%T %D")] No available update!"
	else
		NEED_UPDATE_DB=1
		echo "[$(date +"%T %D")] Update available..."
		echo "[$(date +"%T %D")] Fetching from $GENERIF_BASIC_URL..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $GENERIF_BASIC_URL)
		chmod 664 $GRIFB
		echo "[$(date +"%T %D")] Parsing ..."
		zgrep -P "^9606" $GRIFB |cut -f2,3,5 >$BASEDIR/tmp/GeneRIF_basic
	fi
##dga 
##need to find the download url!!
	echo 'need to come back here to find out the DGA download link!!'
	##need to edit here like above
	NEED_UPDATE_DB=1
	[ ! -e $DGA ] && cp $BASEDIR/tmp/dga/IDMappings.rdf $DGA && echo "[$(date +"%T %D")] Parsing DGA..." && cat $DGA | perl $BASEDIR/dga.pl | tail -n+2 >$BASEDIR/tmp/GeneRIF_dga

fi

if [ $NEED_UPDATE_DB -eq 1 ]; then
	echo "[$(date +"%T %D")] Updating db..."$(date +"%T")
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
	mysqlimport -h $HOST -u $USER -p$PSW $DB -L -c do_acc,entrez_id,pmid,rif --delete $BASEDIR/tmp/GeneRIF_dga
	mysqlimport -h $HOST -u $USER -p$PSW -c gene_id,pmid,rif -L --delete $DB $BASEDIR/tmp/GeneRIF_basic
	echo "[$(date +"%T %D")] Updating HDO ids for DGA data...";
	perl $BASEDIR/updateID.pl $DB $HOST $USER $PSW
	echo "[$(date +"%T %D")] Generating GeneRIF disease2gene..."
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/cal_d2g.sql
fi


exit 0;

















##########
#old version
#########

#create two table base on the ftp file

if [ $USECACHE = 'n' ]; then
echo "updating generif row file..."$(date +"%T")
##old GeneRIF paper
#wget -O $BASEDIR/tmp/GeneRIF_disease2gene.raw  http://projects.bioinformatics.northwestern.edu/do_rif/do_rif.human.txt
##an error in this file in this line :2130	EWSR1-PBX1 fusion gene resulting from a t(1;22)(q23;q12) translocation is associated with myoepithelioma.(\	18383210	C0027070	DOID:2661	with myoepithelioma	1000
#sed -e 's/.(\\/./g' $BASEDIR/tmp/GeneRIF_disease2gene.raw > $BASEDIR/tmp/GeneRIF_disease2gene.txt

#using the new DGA data
#download
wget -O $BASEDIR/tmp/GeneRIF_disease2gene.raw http://dga.nubic.northwestern.edu/ajax/Download.ajax.php

wget -O $BASEDIR/tmp/generifs_basic.gz ftp://ftp.ncbi.nih.gov/gene/GeneRIF/generifs_basic.gz
zgrep -P "^9606" $BASEDIR/tmp/generifs_basic.gz |cut -f2,3,5 >$BASEDIR/tmp/GeneRIF_basic
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql


fi

#parse
cat $BASEDIR/tmp/GeneRIF_disease2gene.raw | perl $BASEDIR/generif.pl | tail -n+2 >$BASEDIR/tmp/GeneRIF_disease2gene_dga.txt

#create db tables
echo "creating generif db table..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql


echo "insering into db..."$(date +"%T")
#mysqlimport -h $HOST -u $USER -p$PSW -L $DB $BASEDIR/tmp/GeneRIF_disease2gene.txt
mysqlimport -h $HOST -u $USER -p$PSW $DB -L -c do_acc,entrez_id,pmid,rif  $BASEDIR/tmp/GeneRIF_disease2gene_dga.txt
mysqlimport -h $HOST -u $USER -p$PSW -c gene_id,pmid,rif -L --delete $DB $BASEDIR/tmp/GeneRIF_basic

echo "updating HDO ids for GeneRIF data..."$(date +"%T")
perl $BASEDIR/updateID.pl $DB $HOST $USER $PSW

#echo "caculating generif_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_generif_gene2disease.sql

