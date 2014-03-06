#!/bin/sh
BASEDIR=$(dirname $0)
clear
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/BioPerl-1.6.0
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/biomart/biomart-perl/lib
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/ensembl-api/ensembl/modules
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/ensembl-api/ensembl-compara/modules
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/ensembl-api/ensembl-variation/modules
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/ensembl-api/ensembl-functgenomics/modules
PERL5LIB=${PERL5LIB}:${PWD}/common/lib/mylib
export PERL5LIB;


functions=$BASEDIR/common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks

config_g=$BASEDIR/config.cnf

##load functions
if [ -f $functions ];then
	. $functions
else
   	echo "$functions is missing, aborting..."
   	exit 1;
fi

##read config file
readcnf $config_g

##clean db

[ $cleandb = 'y' ] && echo $(gettime)" Cleaning db..." && mysql -h $host -u $user -p$psw $db <$BASEDIR/db.sql



if [ $basic = 'y' ]; then
	echo '****************************************************'| tee -a $log
	echo '*********************Basic data*********************'| tee -a $log
	echo '****************************************************'| tee -a $log
	sh $BASEDIR/basic/run.sh 2>&1 | tee -a $log
	echo ''
fi



if [ $ontologies = 'y' ]; then
	echo '****************************************************'| tee -a $log
	echo '*********************Ontologies*********************'| tee -a $log
	echo '****************************************************'| tee -a $log
	sh $BASEDIR/ontologies/hdo/run.sh 2>&1 | tee -a $log
	echo ''
fi


if [ $sources = 'y' ]; then
	echo '****************************************************'| tee -a $log
	echo '**********************Sources***********************'| tee -a $log
	echo '****************************************************'| tee -a $log
	sh $BASEDIR/sources/run.sh 2>&1 | tee -a $log
	echo ''
fi
exit 0;