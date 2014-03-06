#!/bin/sh
BASEDIR=$(dirname $0)

functions=$BASEDIR/../common/functions.sh
scripts=$BASEDIR/scripts

config_g=$BASEDIR/../config.cnf


##load functions
if [ -f $functions ];then
	. $functions
else
   	echo "$functions is missing, aborting..."
   	exit 1;
fi

##read config file
readcnf $config_g

if [ $sources_dga = 'y' ]; then
		echo $(gettime)"Ensembl..."
		sh $BASEDIR/ensembl/run.sh
		echo ''
fi

if [ $source_variation = 'y' ]; then
		echo $(gettime)"Variation..."
		sh $BASEDIR/variation/run.sh
		echo ''
fi



