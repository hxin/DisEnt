BASEDIR=$(dirname $0)
PERL5LIB=${PERL5LIB}:${PWD}/lib/BioPerl-1.6.0
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-api/ensembl/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-api/ensembl-compara/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-api/ensembl-variation/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-api/ensembl-functgenomics/modules
export PERL5LIB;



##read config file
CONFIG_FILE=./config
if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

##exit when error
set -e

echo '\n\n**************************'
echo '**The script is used to update data for DisEnt tool. See log for detail run.'
echo '**Some process taks hours even days to finish. So if just using cache data, turn the USECACHE flag in config file to y'
echo '**To Add more species, you need to edit the config file, if adding new species other than f/m/r/h/z/y then you need to update the ensembl data for homolog'
echo '**if you want to update any of the three source data, you need to rerun the term mapping process!!'
echo '**************************'

echo "\n\n-----------------------------NEW RUN-------------------------------------" >> $LOG

start=$(date +"%T %D")
echo "Job starts at $start..." | tee -a $LOG

##clean tmp file
if [ $CLEANTMP = 'y' ];then 
	echo "[$(date +"%T %D")] Cleaning tmp files..." | tee -a $LOG
	find . -type d -iname 'tmp' | xargs rm -rf;
fi

if [ $CLEANDB = 'y' ];then
	echo "[$(date +"%T %D")] Cleaning db..." | tee -a $LOG
	mysqlshow -u $USER -p$PSW "$DB" >/dev/null 2>&1 && mysqladmin -fb -u $USER -p$PSW drop $DB
fi
exit;
##in order:entrez,omim,generif,ensembl,metamap

##create database if not exist
echo "Create db $DB@$HOST if not exist..." | tee -a $LOG
echo "create database IF NOT EXISTS $DB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" | mysql -h $HOST -u $USER -p$PSW 2>&1| tee -a $LOG

##parpear HDO data
if [ $HDO = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Hdo data..."| tee -a $LOG
sh $BASEDIR/hdo_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear entrez data
if [ $ENTREZ = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Entez data..."| tee -a $LOG
sh $BASEDIR/entrez_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear generif data
if [ $GENERIF = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] GeneRIF data..."| tee -a $LOG
sh $BASEDIR/generif_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear omim data
if [ $OMIM = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Omim data..."| tee -a $LOG
sh $BASEDIR/omim_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear ensembl data
if [ $ENSEMBL = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Ensembl data..."| tee -a $LOG
sh $BASEDIR/ensembl_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi


##parpear metamap data
if [ $METAMAP = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Metamap data..."| tee -a $LOG
sh $BASEDIR/metamap_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear NCBO data
if [ $NCBO = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Ncbo data..." | tee -a $LOG
sh $BASEDIR/ncbo_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi


if [ $JOIN = 'y' ]; then
##create human_gene_dis tables
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Generating All_human_gene2disease tables..."| tee -a $LOG
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db2.sql
exit;
echo 'generating homolog disease tables...'$(date +"%T")
perl $BASEDIR/homolog_dis.pl $DB $HOST $USER $PSW $SPECIES
fi

end=$(date +"%T %D")
echo "[$(date +"%T %D")] END...Current time : $end" | tee -a $LOG
echo "[$(date +"%T %D")] Total:$start ---> $end" | tee -a $LOG
exit;

