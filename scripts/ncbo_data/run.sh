BASEDIR=$(dirname $0)


CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi



[ $NCBO_ENSEMBL = 'y' ] && echo "[$(date +"%T %D")] Ensembl..." && sh $BASEDIR/ensembl/run.sh
[ $NCBO_OMIM = 'y' ] && echo "[$(date +"%T %D")] Omim..." && sh $BASEDIR/omim/run.sh
[ $NCBO_GENERIF = 'y' ] && echo "[$(date +"%T %D")] GeneRIF..." && sh $BASEDIR/generif/run.sh

exit 0;


