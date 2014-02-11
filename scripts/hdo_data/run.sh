BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config
HDO_RAW=$BASEDIR/tmp/doid.obo


if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi


if [ $USECACHE = 'n' ]; then
	echo "[$(date +"%T %D")] Checking for update..."
	(cd $BASEDIR/tmp/ && wget -nv -N --spider $HDO_RAW_URL)
	
	exit;

	echo "[$(date +"%T %D")] Fetching hdo raw file from $HDO_RAW_URL..."
	(cd $BASEDIR/tmp/ && wget -nv -N $HDO_RAW_URL)

	if [ -e $BASEDIR/tmp/check.md5 ]; then
		##no need to update
		md5sum -c --status $BASEDIR/tmp/check.md5
		if [ $? -eq 0 ];then
			echo "[$(date +"%T %D")] You are using the lastest HDO data!"
			exit 0;	
		fi
	fi
fi

##new file available,need to update database
md5sum $HDO_RAW > $BASEDIR/tmp/check.md5
echo "[$(date +"%T %D")] Found newer HDO raw file. Updating...";
echo "[$(date +"%T %D")] Parsing hdo raw file..."
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_terms.pl >$BASEDIR/tmp/DO_terms
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_term2term.pl >$BASEDIR/tmp/DO_term2term
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2synonyms.pl >$BASEDIR/tmp/DO_synonyms
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2xrefs.pl >$BASEDIR/tmp/DO_xrefs
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2altid.pl >$BASEDIR/tmp/DO_altids

echo "[$(date +"%T %D")] Inserting into db..."
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/hdo.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_terms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_term2term
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_synonyms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_xrefs
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_altids


