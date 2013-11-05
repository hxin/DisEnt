BASEDIR=$(dirname $0)
PERL5LIB=${PERL5LIB}:${PWD}/lib/bioperl-1.2.3
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-compara/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-variation/modules
PERL5LIB=${PERL5LIB}:${PWD}/lib/ensembl-functgenomics/modules
export PERL5LIB;

CONFIG_FILE=./config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

export DB;
export HOST;
export USER;
export PSW;
export USECACHE;
export MM_LOC;
export RUNMETAMAP;
set -e



echo 'The script is used to update data for DisEnt tool.'
echo 'Some process taks hours even days to finish. So if just using cache data, turn the USEFTP flag in config file to n,otherwise, y'
echo 'To Add more species, you need to edit the config file, if adding new species other than f/m/r/h/z/y then you need to update the ensembl data for homolog'


#echo "do you want to update hdo data?(y/n)(default n)"
#read HDO
#
#if [ -z "$HDO" ] 
#then HDO="n"
#fi
#
#echo "do you want to update generif data?(y/n)(default n)"
#read GENERIF
#
#if [ -z "$GENERIF" ] 
#then GENERIF="n"
#fi
#
#echo "do you want to update omim data?(y/n)(default n)"
#read OMIM
#
#if [ -z "$OMIM" ] 
#then OMIM="n"
#fi
#
#echo "do you want to update entrez data?(y/n)(default n)"
#read ENTREZ
#
#if [ -z "$ENTREZ" ] 
#then ENTREZ="n"
#fi
#
#echo "do you want to update ensembl data?(y/n)(default n)(26+hours)"
#read ENSEMBL
#
#if [ -z "$ENSEMBL" ] 
#then ENSEMBL="n"
#fi
#
#echo "do you want to update metamap mapping data?(y/n)(default n)"
#read METAMAP
#
#if [ -z "$METAMAP" ] 
#then METAMAP="n"
#fi


start=$(date +"%T")
echo "Start...Current time : $start"

##in order:entrez,omim,generif,ensembl,metamap

##parpear HDO data
if [ $HDO = 'y' ]; then
echo '**************************************************************'
echo 'updating hdo data...'$(date +"%T")
sh $BASEDIR/hdo_data/hdo.sh
echo ''
fi

##parpear entez data
if [ $ENTREZ = 'y' ]; then
echo '**************************************************************'
echo 'updating entez data...'$(date +"%T")
sh $BASEDIR/entrez_data/entrez.sh
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
#$MM_LOC/bin/skrmedpostctl restart
#sleep 10s
#$MM_LOC/bin/wsdserverctl restart
#sleep 180s
echo 'Ensembl...'$(date +"%T")
sh $BASEDIR/metamap_data/ensembl/ensembl.sh
echo 'Omim...'$(date +"%T")
sh $BASEDIR/metamap_data/omim/omim.sh
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
echo ''
fi

##create human_gene_dis tables
echo '**************************************************************'
echo 'generating All_human_gene2disease tables...'$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/db.sql
echo 'generating homolog disease tables...'$(date +"%T")
perl $BASEDIR/homolog_dis.pl $DB $HOST $USER $PSW $SPECIES



end=$(date +"%T")
echo "END...Current time : $end"
echo "Total:$start ---> $end"
exit;
