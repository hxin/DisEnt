BASEDIR=$(dirname $0)
MM_LOC="/home/xin/MetaMap/public_mm"

CONFIG_FILE=$BASEDIR/../../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

if [ $USECACHE = 'n' ]; then
echo "filtering human generifs..."$(date +"%T")
#grep -P "^9606" $BASEDIR/tmp/generifs_basic| cut -f2,3,5 >$BASEDIR/tmp/GeneRIF_basic
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql
mysqlimport -h $HOST -u $USER -p$PSW -c gene_id,pmid,rif -L $DB $BASEDIR/tmp/GeneRIF_basic

echo 'Loading rifs...'$(date +"%T")
perl $BASEDIR/get_rifs.pl $DB $HOST $USER $PSW > $BASEDIR/tmp/all_rifs.txt
echo 'Mapping rifs(3 days)...'$(date +"%T")
sh $MM_LOC/bin/metamap12 -iIDzcys --silent -p  -V 13_hdo $BASEDIR/tmp/all_rifs.txt $BASEDIR/tmp/tmp_rifs_mmtx_0

echo 'Parsing result...'$(date +"%T")
grep -P 'Processing 00000000.tx.1|DOID[0-9]' $BASEDIR/tmp/tmp_rifs_mmtx_0 |perl $BASEDIR/parser.pl >$BASEDIR/tmp/GeneRIF_MetaMap_disease2gene
fi

mysqlimport -h $HOST -u $USER -p$PSW  -L --delete $DB $BASEDIR/tmp/GeneRIF_MetaMap_disease2gene

