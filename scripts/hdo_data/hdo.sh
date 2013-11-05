BASEDIR=$(dirname $0)

if [ $USECACHE = 'n' ]; then
echo "fetching hdo raw file..."$(date +"%T")
wget -O $BASEDIR/tmp/doid.obo http://purl.obolibrary.org/obo/doid.obo
fi

echo "Parsing hdo raw data..."$(date +"%T")
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_terms.pl >$BASEDIR/tmp/DO_terms
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_term2term.pl >$BASEDIR/tmp/DO_term2term
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2synonyms.pl >$BASEDIR/tmp/DO_synonyms
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2xrefs.pl >$BASEDIR/tmp/DO_xrefs
cat $BASEDIR/tmp/doid.obo | perl $BASEDIR/do_do2altid.pl >$BASEDIR/tmp/DO_altids

echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/hdo.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_terms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_term2term
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_synonyms
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_xrefs
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/DO_altids


