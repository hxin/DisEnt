BASEDIR=$(dirname $0)



if [ $USECACHE = 'n' ]; then
echo "mapping disease to HDO...(50min)"$(date +"%T")
perl $BASEDIR/2hdo.pl $DB $HOST $USER $PSW >$BASEDIR/tmp/NCBO_omim2do_raw
#perl $BASEDIR/2hdo.pl $DB $HOST $USER $PSW
fi

echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/run.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/NCBO_omim2do_raw
echo "updating hdo deiease name..."$(date +"%T")
perl $BASEDIR/map_hdo_des.pl $DB $HOST $USER $PSW

#echo "joining MetaMap result..."
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_all.sql
