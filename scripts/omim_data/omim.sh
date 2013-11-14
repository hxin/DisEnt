BASEDIR=$(dirname $0)

CONFIG_FILE=$BASEDIR/../config

if [ -f $CONFIG_FILE ]; then
        . $CONFIG_FILE
fi


#create two table base on the ftp file
if [ $USECACHE = 'n' ]; then
wget -O $BASEDIR/tmp/mim2gene.txt ftp://anonymous:xin.he%40ed.ac.uk@grcf.jhmi.edu/OMIM/mim2gene.txt
wget -O $BASEDIR/tmp/morbidmap.txt ftp://grcf.jhmi.edu/OMIM/morbidmap
fi


#create db tables
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/omim.sql

#disease2gene
echo 'Parsing omim raw file...'$(date +"%T")
cat $BASEDIR/tmp/morbidmap| perl $BASEDIR/disease2gene/omim_d2g.pl >$BASEDIR/tmp/OMIM_disease2gene.txt
mysqlimport -h $HOST -u $USER -p$PSW -c description,disorder_mim_acc,gene_symbol,locus_mim_acc,location -L $DB $BASEDIR/tmp/OMIM_disease2gene.txt
#mim2gene

#sed -e 's/\t-/ /g' $BASEDIR/tmp/mim2gene.txt | tail -n+2 > $BASEDIR/tmp/OMIM_mim2gene.txt
cat $BASEDIR/tmp/mim2gene.txt | tail -n+2 > $BASEDIR/tmp/OMIM_mim2gene.txt

echo 'inserting into db...'$(date +"%T")
mysqlimport -h $HOST -u $USER -p$PSW -c mim_acc,type,entrez_id,gene_symbol -L $DB $BASEDIR/tmp/OMIM_mim2gene.txt


#echo "caculating omim_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_omim_gene2disease.sql
