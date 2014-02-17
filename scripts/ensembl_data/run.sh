BASEDIR=$(dirname $0)


CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi


H_GENE=$BASEDIR/tmp/ENSEMBL_human_gene
CHUNK=$BASEDIR/tmp/chunks

##update ensemb api
if [ $ENSEMBL_API = 'y' ]; then
	echo "[$(date +"%T %D")] Updating ensembl API..."
	(cd $LIB; wget -nv -N $ENSEMBL_LASTEST_API_URL)
	(cd $LIB; tar xfz $LIB/ensembl-api.tar.gz)
	(cd $LIB; wget -nv -O ./bioperl.tar.gz $BIOPERL_URL)
	(cd $LIB; tar xfz $LIB/bioperl.tar.gz)
fi


if [ $USECACHE = 'n' ]; then
	#######fetch human gene
	echo "[$(date +"%T %D")] Fetching human gene..."
	perl $BASEDIR/fetch_human_gene.pl > $H_GENE

	#######fetch homolog
	if [ $ENSEMBL_HOMOLOG = 'y' ];then
		echo "[$(date +"%T %D")] Prepare for homolog/orthology mapping of all human gene..."
		echo "[$(date +"%T %D")] Start chunking files..."
		echo "[$(date +"%T %D")] Create/Empty chunk folder..."
		( [ -d $CHUNK ] && rm -f $CHUNK/* ) || mkdir $BASEDIR/tmp/chunks;
		echo "[$(date +"%T %D")] Chunking file..."
		if [ $DEBUG = 'n' ];then
			cp $H_GENE $CHUNK/ENSEMBL_human_gene 
		else
			head -100 $H_GENE > $CHUNK/ENSEMBL_human_gene 
		fi
		(cd $CHUNK && split -n l/$ENSEMBL_CHUNK_NUMBER -a 3 -e -d ENSEMBL_human_gene chunk_ && rm -f ./ENSEMBL_human_gene)
		#ls $CHUNK

		echo "[$(date +"%T %D")] Fetching homologs, this may take hours...(2h for fly) UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"
		for line in $(find $CHUNK -iname 'chunk_*'); do 
		     perl $BASEDIR/fetch_homolog.pl $SPECIES $line > ${line}_parsed &
		done

		echo "[$(date +"%T %D")] Waiting for process to be finished..."
		wait
		echo "[$(date +"%T %D")] Finish!"
		echo "[$(date +"%T %D")] Joining result..."
	
		for line in $(find $CHUNK -iname 'chunk_*_parsed'); do 
		     cat $line >> $CHUNK/all
		done
		cp $CHUNK/all $CHUNK/../ENSEMBL_human_homolog
		NEED_UPDATE_DB=1
	fi
	
	#######fetch variation
	if [ $ENSEMBL_VARIATION = 'y' ];then
		echo "[$(date +"%T %D")] Fetching Variation and Phenotypes..."
		perl $BASEDIR/fetch_variation_pehnotype.pl $DEBUG> $BASEDIR/tmp/ENSEMBL_variation2phenotype
		echo "[$(date +"%T %D")] Parsing..."
		grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype|cut -f 1,2,3,4 > $BASEDIR/tmp/ENSEMBL_variation
		grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype|cut -f 1,5,6,7,8 > $BASEDIR/tmp/ENSEMBL_v2p
		NEED_UPDATE_DB=1
	fi
	
fi


##get all human gene homolog into db ENSEMBL_human_homolog
if [ $NEED_UPDATE_DB -eq 1 ]; then
	echo "[$(date +"%T %D")] Updabing db..."
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
	mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_human_gene
	mysqlimport -h $HOST -u $USER -p$PSW --delete -c human,homolog,dn_ds,type,species -L $DB $BASEDIR/tmp/ENSEMBL_human_homolog
	mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,chr,start,end -L $DB $BASEDIR/tmp/ENSEMBL_variation
	mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,phenotype_source,phenotype_source_id,phenotype_id,phenotype_description -L $DB $BASEDIR/tmp/ENSEMBL_v2p

	echo "[$(date +"%T %D")] Caculating variation2gene (20 minutes)..."
	perl $BASEDIR/variation2gene.pl $DB $HOST $USER $PSW >$BASEDIR/tmp/ENSEMBL_v2g
	echo "[$(date +"%T %D")] Updabing db..."
	mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_v2g

	echo "[$(date +"%T %D")] Caculating VARIATION_g2d..."
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_d2g.sql
	echo "[$(date +"%T %D")] homolog have not been mapped to entrez! Need to come back here!!..."
fi

exit 0;

echo "mapping human homolog to entrez id..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/map_homolog_to_entrez.sql




exit 0;


#####################


##metamap
echo 'start metamap mapping...'$(date +"%T")
echo 'start metamap mapping...'$(date +"%T") >>$LOG
for i in $BASEDIR/tmp/chunks/pts_chunk_*
do
    if test -f "$i" 
    then
	sh $MM_LOC/bin/metamap12 -iIDzycs --silent -p  -V 13_hdo $i $i'_parsed' &
    fi
done


echo 'waiting for process to be finished...'$(date +"%T")
echo 'waiting for process to be finished...'$(date +"%T") >>$LOG
wait

echo 'finish!'$(date +"%T")
echo 'finish!'$(date +"%T") >> $LOG
echo 'joining result...'
echo 'joining result...' >>$LOG

ls $BASEDIR/tmp/chunks/pts_chunk_*_parsed
ls $BASEDIR/tmp/chunks/pts_chunk_*_parsed >>$LOG

for i in $BASEDIR/tmp/chunks/pts_chunk_*_parsed
do
    if test -f "$i" 
    then
	cat $i >> $BASEDIR/tmp/chunks/all
    fi
done

echo 'done!'$(date +"%T")
echo 'done!'$(date +"%T") >>$LOG


#####################


exit;

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
	#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
	#mysqlimport -h $HOST -u $USER -p$PSW $DB -L -c do_acc,entrez_id,pmid,rif --delete $BASEDIR/tmp/GeneRIF_dga
	#mysqlimport -h $HOST -u $USER -p$PSW -c gene_id,pmid,rif -L --delete $DB $BASEDIR/tmp/GeneRIF_basic
	echo "[$(date +"%T %D")] Updating HDO ids for DGA data...";
	perl $BASEDIR/updateID.pl $DB $HOST $USER $PSW
	echo "[$(date +"%T %D")] Generating GeneRIF disease2gene..."
	mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/cal_d2g.sql
fi









exit 0;


if [ $USECACHE = 'n' ]; then
echo "fetching human gene..."$(date +"%T")
#perl $BASEDIR/fetch_human_gene.pl >$BASEDIR/tmp/ENSEMBL_human_gene

echo "fetching homologs, this may take hours...(26+ hours to be exact...) UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"$(date +"%T")
#perl $BASEDIR/fetch_homolog.pl $SPECIES > $BASEDIR/tmp/ENSEMBL_human_homolog

#echo "fetching variation..."$(date +"%T")
#perl $BASEDIR/fetch_variation.pl > $BASEDIR/tmp/ENSEMBL_variation

echo "fetching variation phenotypes(20+ hours)..."$(date +"%T")
perl $BASEDIR/fetch_variation_pehnotype.pl > $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw
grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw|cut -f 1,2,3,4 > $BASEDIR/tmp/ENSEMBL_variation
grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw|cut -f 1,5,6,7,8 > $BASEDIR/tmp/ENSEMBL_variation2phenotype
fi


##get all human gene homolog into db ENSEMBL_human_homolog
echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/ensembl.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_human_gene
mysqlimport -h $HOST -u $USER -p$PSW --delete -c human,homolog,dn_ds,type,species -L $DB $BASEDIR/tmp/ENSEMBL_human_homolog
mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,chr,start,end -L $DB $BASEDIR/tmp/ENSEMBL_variation
mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,phenotype_source,phenotype_source_id,phenotype_id,phenotype_description -L $DB $BASEDIR/tmp/ENSEMBL_variation2phenotype

echo "mapping human homolog to entrez id..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/map_homolog_to_entrez.sql

echo "caculating variation2gene(10mins)...UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"$(date +"%T")
#perl $BASEDIR/variation2gene.pl $DB $HOST $USER $PSW >$BASEDIR/tmp/ENSEMBL_variation2gene
echo "inserting into db..."$(date +"%T")
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_variation2gene


#echo "caculating VARIATION_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_variation_gene2disease.sql
