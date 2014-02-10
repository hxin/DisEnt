BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi


if [ $USECACHE = 'n' ]; then
echo 'loading rifs from db...'$(date +"%T")
echo 'loading rifs from db...'$(date +"%T") >>$LOG
perl $BASEDIR/get_des.pl $DB $HOST $USER $PSW > $BASEDIR/tmp/des

echo 'start chunking files...'$(date +"%T")
echo 'start chunking files...'$(date +"%T") >>$LOG
echo 'empty chunk folder...'$(date +"%T")
echo 'empty chunk folder...'$(date +"%T") >> $LOG
rm $BASEDIR/tmp/chunks/*

echo 'spliting file...'$(date +"%T")
echo 'spliting file...'$(date +"%T") >> $LOG
split -n l/$METAMAP_CHUNK_NUMBER -a 3 -d $BASEDIR/tmp/des des_chunk_
mv `pwd`/des_chunk_* $BASEDIR/tmp/chunks/
ls $BASEDIR/tmp/chunks/
ls $BASEDIR/tmp/chunks/ >>$LOG


##metamap
echo 'start metamap mapping...'$(date +"%T")
echo 'start metamap mapping...'$(date +"%T") >>$LOG
for i in $BASEDIR/tmp/chunks/des_chunk_*
do
    if test -f "$i" 
    then
	sh $MM_LOC/bin/metamap12 -iIDzycs --silent -p  -V 13_hdo $i $i'_parsed' &
    fi
done


echo 'waiting for process to be finished...(40hours)'$(date +"%T")
echo 'waiting for process to be finished...'$(date +"%T") >>$LOG
wait

echo 'finish!'$(date +"%T")
echo 'finish!'$(date +"%T") >> $LOG
echo 'joining result...'
echo 'joining result...' >>$LOG

ls $BASEDIR/tmp/chunks/des_chunk_*_parsed
ls $BASEDIR/tmp/chunks/des_chunk_*_parsed >>$LOG

for i in $BASEDIR/tmp/chunks/des_chunk_*_parsed
do
    if test -f "$i" 
    then
	cat $i >> $BASEDIR/tmp/chunks/all
    fi
done

echo 'done!'$(date +"%T")
echo 'done!'$(date +"%T") >>$LOG

cp $BASEDIR/tmp/chunks/all $BASEDIR/tmp/tmp_rifs_mmtx_0

echo 'Parsing result...'$(date +"%T")
echo 'Parsing result...'$(date +"%T") >>$LOG


grep -P 'Processing|DOID[0-9]' $BASEDIR/tmp/tmp_rifs_mmtx_0 | perl $BASEDIR/parser.pl >$BASEDIR/tmp/MetaMap_rif2do_raw

fi

echo "inserting into db..."$(date +"%T")
echo "inserting into db..."$(date +"%T") >>$LOG

mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/MetaMap_rif2do_raw
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/add_des.sql







