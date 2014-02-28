#!/bin/sh
BASEDIR=$(dirname $0)


functions=$BASEDIR/../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp

config_g=$BASEDIR/../../config.cnf
config_l=$BASEDIR/config.cnf

##load functions
if [ -f $functions ]; then
        . $functions
fi

##read config file
readcnf $config_g && readcnf $config_l

##create tmp folder
[ ! -d $tmp ] && mkdir $tmp

##awk -F ":" '/^id:/ {ofn=$3 ".txt"} ofn {print > ofn}'

if [ $checkupdate = 'y' ]; then
	echo $(gettime)" Checking update..."
	( [ -n "$(cd $tmp; wget -nv -N --spider $HDO_RAW_URL 2>&1 | grep '200 OK')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	NEED_UPDATE_DB=$?
	[ $NEED_UPDATE_DB -eq 0 ] && echo $(gettime)"	You are using the lastest HDO data!" && exit 0 || \
	if [ $NEED_UPDATE_DB -eq 1 ];then
		echo $(gettime)"	Update available..."; 
		echo $(gettime)"	Fetching from $HDO_RAW_URL..." 
		(cd $tmp/ && wget -nv -N $HDO_RAW_URL);
		echo $(gettime)"	Parsing..."
		cat $tmp/doid.obo | perl $scripts/do_terms.pl >$tmp/DO_terms
		cat $tmp/doid.obo | perl $scripts/do_term2term.pl >$tmp/DO_term2term
		cat $tmp/doid.obo | perl $scripts/do_do2synonyms.pl >$tmp/DO_synonyms
		cat $tmp/doid.obo | perl $scripts/do_do2xrefs.pl >$tmp/DO_xrefs
		cat $tmp/doid.obo | perl $scripts/do_do2altid.pl >$tmp/DO_altids
	fi
	echo echo $(gettime)"	Done!"
fi

exit 0;
##new file available,need to update database

if [ $NEED_UPDATE_DB -eq 1 ];then
echo "[$(date +"%T %D")] Updating db..."
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/hdo.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $tmp/DO_terms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $tmp/DO_term2term
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $tmp/DO_synonyms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $tmp/DO_xrefs
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $tmp/DO_altids
fi

