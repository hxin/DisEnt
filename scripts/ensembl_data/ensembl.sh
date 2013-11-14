BASEDIR=$(dirname $0)


if [ $USECACHE = 'n' ]; then
echo "fetching human gene..."$(date +"%T")
#perl $BASEDIR/fetch_human_gene.pl >$BASEDIR/tmp/ENSEMBL_human_gene

echo "fetching homologs, this may take hours...(26+ hours to be exact...) UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"$(date +"%T")
#perl $BASEDIR/fetch_homolog.pl $SPECIES > $BASEDIR/tmp/ENSEMBL_human_homolog

#echo "fetching variation..."$(date +"%T")
#perl $BASEDIR/fetch_variation.pl > $BASEDIR/tmp/ENSEMBL_variation

echo "fetching variation phenotypes(20+ hours)..."$(date +"%T")
perl $BASEDIR/fetch_variation_pehnotype.pl > $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw
grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw|cut -f 1,2,3,4 > $BASEDIR/tmp/ENSEMBL_variation
grep ^rs $BASEDIR/tmp/ENSEMBL_variation2phenotype.raw|cut -f 1,5,6,7,8 > $BASEDIR/tmp/ENSEMBL_variation2phenotype
fi


##get all human gene homolog into db ENSEMBL_human_homolog
echo "inserting into db..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/ensembl.sql
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_human_gene
mysqlimport -h $HOST -u $USER -p$PSW --delete -c human,homolog,dn_ds,type,species -L $DB $BASEDIR/tmp/ENSEMBL_human_homolog
mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,chr,start,end -L $DB $BASEDIR/tmp/ENSEMBL_variation
mysqlimport -h $HOST -u $USER -p$PSW --delete -c variation_id,phenotype_source,phenotype_source_id,phenotype_id,phenotype_description -L $DB $BASEDIR/tmp/ENSEMBL_variation2phenotype

echo "mapping human homolog to entrez id..."$(date +"%T")
mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/map_homolog_to_entrez.sql

echo "caculating variation2gene(10mins)...UNCOMMENT!!!!!HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!"$(date +"%T")
#perl $BASEDIR/variation2gene.pl $DB $HOST $USER $PSW >$BASEDIR/tmp/ENSEMBL_variation2gene
echo "inserting into db..."$(date +"%T")
mysqlimport -h $HOST -u $USER -p$PSW --delete -L $DB $BASEDIR/tmp/ENSEMBL_variation2gene


#echo "caculating VARIATION_human_gene2disease..."$(date +"%T")
#mysql -h $HOST -u $USER -p$PSW $DB <$BASEDIR/caculate_variation_gene2disease.sql
