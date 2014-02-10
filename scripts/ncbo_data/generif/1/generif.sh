BASEDIR=$(dirname $0)


CONFIG_FILE=$BASEDIR/../../../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

echo 'loading rifs from db...'$(date +"%T")
echo 'loading rifs from db...'$(date +"%T") >>$LOG


echo 'start chunking rif files...'$(date +"%T")
echo 'start chunking rif files...'$(date +"%T") >>$LOG

echo 'empty chunk folder...'$(date +"%T")
echo 'empty chunk folder...'$(date +"%T") >> $LOG
rm $BASEDIR/tmp/chunks/*

echo 'spliting file...'$(date +"%T")
echo 'spliting file...'$(date +"%T") >> $LOG
split -n l/$NCBO_CHUNK_NUMBER -a 3 -d $BASEDIR/tmp/rifs rifs_chunk_
mv `pwd`/rifs_chunk_* $BASEDIR/tmp/chunks/
ls $BASEDIR/tmp/chunks/
ls $BASEDIR/tmp/chunks/ >>$LOG

##query NCBO 
echo 'start queries ncbo...'$(date +"%T")
echo 'start queries ncbo...'$(date +"%T") >>$LOG
for i in $BASEDIR/tmp/chunks/rifs_chunk_*
do
    if test -f "$i" 
    then
       	perl $BASEDIR/2hdo.pl $DB $HOST $USER $PSW $i &
    fi
done

echo 'waiting for process to be finished...'$(date +"%T")
echo 'waiting for process to be finished...'$(date +"%T") >>$LOG
wait

echo 'finish!'$(date +"%T")
echo 'finish!'$(date +"%T") >> $LOG
echo 'joining result...'
echo 'joining result...' >>$LOG
ls $BASEDIR/tmp/chunks/rifs_chunk_*_parsed
ls $BASEDIR/tmp/chunks/rifs_chunk_*_parsed >>$LOG
for i in $BASEDIR/tmp/chunks/rifs_chunk_*_parsed
do
    if test -f "$i" 
    then
       	#perl $BASEDIR/2hdo.pl $DB $HOST $USER $PSW $i
	cat $i >> $BASEDIR/tmp/chunks/all
    fi
done

echo 'done!'$(date +"%T")
echo 'done!'$(date +"%T") >>$LOG
#cat $BASEDIR/tmp/chunks/all
cp $BASEDIR/tmp/chunks/all $BASEDIR/tmp/NCBO_rif2do_raw
exit;


mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/NCBO_rif2do_raw
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/add_des.sql

