BASEDIR=$(dirname $0)
PERL5LIB=${PERL5LIB}:${PWD}/lib/bioperl-1.2.3
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-compara/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-variation/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-functgenomics/modules
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
	find . -type f -name \*.old -exec rm -f {} \;
fi

##in order:entrez,omim,generif,ensembl,metamap

##create database if not exist
echo "Create db $DB@$HOST if not exist..." | tee -a $LOG
echo "create database IF NOT EXISTS $DB DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci" | mysql -h $HOST -u $USER -p$PSW 2>&1| tee -a $LOG

##parpear HDO data
if [ $HDO = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Updating hdo data..."| tee -a $LOG
sh $BASEDIR/hdo_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear entrez data
if [ $ENTREZ = 'y' ]; then
echo '**************************************************************'| tee -a $LOG
echo "[$(date +"%T %D")] Updating entez data..."| tee -a $LOG
sh $BASEDIR/entrez_data/run.sh 2>&1 | tee -a $LOG
echo ''
fi

##parpear generif data
if [ $GENERIF = 'y' ]; then
echo '**************************************************************'
echo 'updating GeneRIF data...'$(date +"%T")
sh $BASEDIR/generif_data/generif.sh
echo ''
fi

##parpear omim data
if [ $OMIM = 'y' ]; then
echo '**************************************************************'
echo 'updating omim data...'$(date +"%T")
sh $BASEDIR/omim_data/omim.sh
echo ''
fi

##parpear ensembl data
if [ $ENSEMBL = 'y' ]; then
echo '**************************************************************'
echo 'updating ensembl data...'$(date +"%T")
sh $BASEDIR/ensembl_data/ensembl.sh
echo ''
fi


##parpear metamap data
if [ $METAMAP = 'y' ]; then
echo '**************************************************************'
echo 'updating metamap data...'$(date +"%T")
echo 'initializing...'
#$MM_LOC/bin/skrmedpostctl start
#sleep 2s
#$MM_LOC/bin/wsdserverctl start
#sleep 120s
echo 'Ensembl...'$(date +"%T")
sh $BASEDIR/metamap_data/ensembl/ensembl.sh
echo 'Omim...'$(date +"%T")
sh $BASEDIR/metamap_data/omim/omim.sh
echo 'GeneRIF...'$(date +"%T")
sh $BASEDIR/metamap_data/generif/generif.sh
#$MM_LOC/bin/skrmedpostctl start
#sleep 2s
#$MM_LOC/bin/wsdserverctl start
#sleep 10s
echo ''
fi

##parpear NCBO data
if [ $NCBO = 'y' ]; then
echo '**************************************************************'
echo 'updating ncbo data...'$(date +"%T")
echo 'Ensembl...'$(date +"%T")
sh $BASEDIR/ncbo_data/ensmebl/run.sh
echo 'Omim...'$(date +"%T")
sh $BASEDIR/ncbo_data/omim/run.sh
echo 'GeneRIF...'$(date +"%T")
sh $BASEDIR/ncbo_data/generif/generif.sh
echo ''
fi


if [ $JOIN = 'y' ]; then
##create human_gene_dis tables
echo '**************************************************************'
echo 'generating All_human_gene2disease tables...'$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
echo 'generating homolog disease tables...'$(date +"%T")
perl $BASEDIR/homolog_dis.pl $DB $HOST $USER $PSW $SPECIES
fi

end=$(date +"%T")
echo "END...Current time : $end"
echo "Total:$start ---> $end"
exit;

