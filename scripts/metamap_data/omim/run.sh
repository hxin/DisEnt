BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

CHUNK=$BASEDIR/tmp/chunks
[ ! -d $BASEDIR/tmp ] && mkdir $BASEDIR/tmp;
if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Loading OMIM disease from db..."
	perl $BASEDIR/get_dis.pl $DB $HOST $USER $PSW $DEBUG > $BASEDIR/tmp/dis

	echo "[$(date +"%T %D")] Start chunking files..."
	echo "[$(date +"%T %D")] Create/Empty chunk folder..."
	( [ -d $CHUNK ] && rm -f $CHUNK/* ) || mkdir $BASEDIR/tmp/chunks;

	echo "[$(date +"%T %D")] Chunking file..."
	(cp $BASEDIR/tmp/dis $CHUNK/dis && cd $CHUNK && split -n l/$METAMAP_CHUNK_NUMBER -a 3 -d ./dis chunk_ && rm -f ./dis)
	#ls $CHUNK


##metamap
	echo "[$(date +"%T %D")] Start metamap mapping..."

	for line in $(find $CHUNK -iname 'chunk_*'); do 
		sh $MM_LOC/bin/metamap12 -iIDzycs --silent -p  -V 13_hdo $line ${line}_parsed &
	done

	echo "[$(date +"%T %D")] Waiting for process to be finished..."
	wait
	echo "[$(date +"%T %D")] Finish!"
	echo "[$(date +"%T %D")] Joining result..."
	for line in $(find $CHUNK -iname 'chunk_*_parsed'); do 
		cat $line >> $CHUNK/all
	done
	cp $CHUNK/all $CHUNK/../tmp_mmtx_0
fi


echo "[$(date +"%T %D")] Parsing result..."
grep -P 'Processing|DOID[0-9]' $BASEDIR/tmp/tmp_mmtx_0 >$BASEDIR/tmp/tmp_mmtx_1
perl $BASEDIR/omim.pl $BASEDIR/tmp/tmp_mmtx_1 >$BASEDIR/tmp/MetaMap_omim2do_raw

echo "[$(date +"%T %D")] Updating db..."
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/omim.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/MetaMap_omim2do_raw
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/add_des.sql


exit 0;


#echo 'Sorting mapping...'$(date +"%T")
#perl $BASEDIR/omim_average_score.pl $DB $HOST $USER $PSW  >$BASEDIR/tmp/MetaMap_omim2do
#mysqlimport -h $HOST -u $USER -p$PSW -L $DB $BASEDIR/tmp/MetaMap_omim2do

#echo "caculating omim_human_disease_hdo table..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/calculate_human_disease_hdo.sql

