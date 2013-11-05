BASEDIR=$(dirname $0)
#MM_LOC="/home/xin/MetaMap/public_mm"

if [ $USECACHE = 'n' ]; then
echo 'Loading omim disease...'$(date +"%T")
perl $BASEDIR/get_dis.pl  $DB $HOST $USER $PSW > $BASEDIR/tmp/omim_all_dis.txt

echo 'mapping omim disease to hdo(an hour)...'$(date +"%T")
#sh $MM_LOC/bin/metamap12 -iIDzcys --silent -p  -V 13_hdo_active_umls $BASEDIR/tmp/omim_all_dis.txt $BASEDIR/tmp/tmp_omim_mmtx_0
sh $MM_LOC/bin/metamap12 -iIDzcys --silent -p  -V 13_hdo $BASEDIR/tmp/omim_all_dis.txt $BASEDIR/tmp/tmp_omim_mmtx_0

echo 'Parsing result...'$(date +"%T")
grep -P 'Processing|DOID[0-9]' $BASEDIR/tmp/tmp_omim_mmtx_0 >$BASEDIR/tmp/tmp_omim_mmtx_1
perl $BASEDIR/omim.pl $DB $HOST $USER $PSW $BASEDIR/tmp/tmp_omim_mmtx_1 | tail -n +2 >$BASEDIR/tmp/MetaMap_omim2do_raw
fi

echo 'inserting into db...'$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/omim.sql
mysqlimport -h $HOST -u $USER -p$PSW -c omim_description,disorder_mim_acc,do_acc_1,do_description_1,score_1,do_acc_2,do_description_2,score_2,do_acc_3,do_description_3,score_3 -L $DB $BASEDIR/tmp/MetaMap_omim2do_raw
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/omim2.sql


echo 'Sorting mapping...'$(date +"%T")
perl $BASEDIR/omim_average_score.pl $DB $HOST $USER $PSW  >$BASEDIR/tmp/MetaMap_omim2do
mysqlimport -h $HOST -u $USER -p$PSW -L $DB $BASEDIR/tmp/MetaMap_omim2do

echo "caculating omim_human_disease_hdo table..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/calculate_human_disease_hdo.sql

exit 0
