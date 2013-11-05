BASEDIR=$(dirname $0)
MM_LOC="/home/xin/MetaMap/public_mm"

CONFIG_FILE=$BASEDIR/../../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi


if [ $USECACHE = 'n' ]; then
echo "mapping disease to HDO(4days)..."$(date +"%T")
#perl $BASEDIR/2hdo.pl $DB $HOST $USER $PSW >$BASEDIR/tmp/GeneRIF_NCBO_disease2gene.raw
##need to parse the result
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql
mysqlimport -h $HOST -u $USER -p$PSW  -L $DB $BASEDIR/tmp/GeneRIF_NCBO_disease2gene
fi
