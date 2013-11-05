BASEDIR=$(dirname $0)
#MM_LOC="/home/xin/MetaMap/public_mm"


if [ $USECACHE = 'n' ]; then
echo 'Loading ensembl disease...'$(date +"%T")
perl $BASEDIR/get_dis.pl  $DB $HOST $USER $PSW > $BASEDIR/tmp/ensembl_all_dis.txt

echo 'mapping ensembl disease to hdo(an hour)...'$(date +"%T")
#sh $MM_LOC/bin/metamap12 -iIDzcys --silent -p  -V 13_hdo_active_umls $BASEDIR/tmp/ensembl_all_dis.txt $BASEDIR/tmp/tmp_ensembl_mmtx_0
## I used 13_hdo_active_unls before but it turns out that some of the umls synonyms turn the perform to wrong direction. For example,
## GALLBLADDER DISEASE 1 should be mapped to DOID0000000:gallbladder disease. However, umls has a synonym for the term  DOID1949:GALLBLADDER DISEASE 1 (cholecystitis) that will result in a wrong mapping.
## and I decide to use obsoleted terms again!
sh $MM_LOC/bin/metamap12 -iIDzcys --silent -p  -V 13_hdo $BASEDIR/tmp/ensembl_all_dis.txt $BASEDIR/tmp/tmp_ensembl_mmtx_0

echo 'Parsing result...'$(date +"%T")
grep -P 'Processing|DOID[0-9]' $BASEDIR/tmp/tmp_ensembl_mmtx_0 >$BASEDIR/tmp/tmp_ensembl_mmtx_1
perl $BASEDIR/ensembl.pl $DB $HOST $USER $PSW $BASEDIR/tmp/tmp_ensembl_mmtx_1 | tail -n +2 >$BASEDIR/tmp/MetaMap_ensembl2do_raw
fi

echo 'inserting into db...'$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/ensembl.sql
mysqlimport -h $HOST -u $USER -p$PSW -c phenotype_description,phenotype_id,do_acc_1,do_description_1,score_1,do_acc_2,do_description_2,score_2,do_acc_3,do_description_3,score_3 -L $DB $BASEDIR/tmp/MetaMap_ensembl2do_raw
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/ensembl2.sql

echo 'Sorting mapping...'$(date +"%T")
perl $BASEDIR/ensembl_average_score.pl $DB $HOST $USER $PSW  >$BASEDIR/tmp/MetaMap_ensembl2do
mysqlimport -h $HOST -u $USER -p$PSW -L $DB $BASEDIR/tmp/MetaMap_ensembl2do

echo "caculating ensembl_human_disease_hdo table..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/calculate_human_disease_hdo.sql

exit 0
