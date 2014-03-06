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

if [ $ontologies_hdo = 'y' ]; then
		echo $(gettime)"HDO..."
		sh $BASEDIR/hdo/run.sh
		echo ''
fi
