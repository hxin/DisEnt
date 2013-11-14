BASEDIR=$(dirname $0)
#create two table base on the ftp file

if [ $USECACHE = 'n' ]; then
echo "updating generif row file..."$(date +"%T")
##old GeneRIF paper
#wget -O $BASEDIR/tmp/GeneRIF_disease2gene.raw  http://projects.bioinformatics.northwestern.edu/do_rif/do_rif.human.txt
##an error in this file in this line :2130	EWSR1-PBX1 fusion gene resulting from a t(1;22)(q23;q12) translocation is associated with myoepithelioma.(\	18383210	C0027070	DOID:2661	with myoepithelioma	1000
#sed -e 's/.(\\/./g' $BASEDIR/tmp/GeneRIF_disease2gene.raw > $BASEDIR/tmp/GeneRIF_disease2gene.txt

#using the new DGA data
#download
#wget -O $BASEDIR/tmp/GeneRIF_disease2gene.raw http://dga.nubic.northwestern.edu/ajax/Download.ajax.php
#parse
cat $BASEDIR/tmp/GeneRIF_disease2gene.raw | perl $BASEDIR/generif.pl | tail -n+2 >$BASEDIR/tmp/GeneRIF_disease2gene.txt
fi


#create db tables
echo "creating generif db table..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/generif.sql

echo "insering into db..."$(date +"%T")
#mysqlimport -h $HOST -u $USER -p$PSW -L $DB $BASEDIR/tmp/GeneRIF_disease2gene.txt
mysqlimport -h $HOST -u $USER -p$PSW $DB -L -c do_acc,entrez_id,pmid,rif  $BASEDIR/tmp/GeneRIF_disease2gene.txt

echo "updating HDO ids for GeneRIF data..."$(date +"%T")
perl $BASEDIR/updateID.pl $DB $HOST $USER $PSW

#echo "caculating generif_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_generif_gene2disease.sql

