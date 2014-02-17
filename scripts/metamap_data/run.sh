BASEDIR=$(dirname $0)


CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi

echo "[$(date +"%T %D")] Initializing local metamap server..."
[ $METAMAP_SKR = 'y' ] && echo "[$(date +"%T %D")] Starting Skrmedpostctl..." && $MM_LOC/bin/skrmedpostctl start
[ $METAMAP_SKR = 'y' ] && echo "[$(date +"%T %D")] Sleep for 5 seconds..." && sleep 5s

[ $METAMAP_WSD = 'y' ] && echo "[$(date +"%T %D")] Starting Wsdserverctl..." && $MM_LOC/bin/wsdserverctl start
[ $METAMAP_WSD = 'y' ] && echo "[$(date +"%T %D")] Sleep for 120 seconds..." && sleep 120s



[ $METAMAP_ENSEMBL = 'y' ] && echo "[$(date +"%T %D")] Ensembl..." && sh $BASEDIR/ensembl/run.sh
[ $METAMAP_OMIM = 'y' ] && echo "[$(date +"%T %D")] Omim..." && sh $BASEDIR/omim/run.sh
[ $METAMAP_GENERIF = 'y' ] && echo "[$(date +"%T %D")] GeneRIF..." && sh $BASEDIR/generif/run.sh

exit 0;
