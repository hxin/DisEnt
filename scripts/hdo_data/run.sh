BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config
HDO_RAW=$BASEDIR/tmp/doid.obo


if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Checking update..."
	( [ -n "$(cd $BASEDIR/tmp/; wget -nv -N --spider $HDO_RAW_URL 2>&1 | grep '200 OK')" ] && exit 1; exit 0; )
	##1 needs update, 0 don't.
	NEED_UPDATE_DB=$?
	[ $NEED_UPDATE_DB -eq 0 ] && echo "[$(date +"%T %D")] You are using the lastest HDO data!" && exit 0 || \
	if [ $NEED_UPDATE_DB -eq 1 ];then
		echo "[$(date +"%T %D")] Update available..."; 
		echo "[$(date +"%T %D")] Fetching from $HDO_RAW_URL..." 
		(cd $BASEDIR/tmp/ && wget -nv -N $HDO_RAW_URL);
		echo "[$(date +"%T %D")] Parsing..."
		cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_terms.pl >$BASEDIR/tmp/DO_terms
		cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_term2term.pl >$BASEDIR/tmp/DO_term2term
		cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2synonyms.pl >$BASEDIR/tmp/DO_synonyms
		cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2xrefs.pl >$BASEDIR/tmp/DO_xrefs
		cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2altid.pl >$BASEDIR/tmp/DO_altids
	fi
fi

##new file available,need to update database
if [ $NEED_UPDATE_DB -eq 1 ];then


echo "[$(date +"%T %D")] Updating db..."
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/hdo.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_terms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_term2term
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_synonyms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_xrefs
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_altids
fi

