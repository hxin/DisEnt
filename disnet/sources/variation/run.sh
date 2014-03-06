#!/bin/sh
BASEDIR=$(dirname $0)

functions=$BASEDIR/../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks
data=$BASEDIR/data
queries=$scripts/queries

config_g=$BASEDIR/../../config.cnf
config_l=$BASEDIR/config.cnf

##load functions
if [ -f $functions ];then
	. $functions
else
   	echo "$functions is missing, aborting..."
   	exit 1;
fi

##read config file
readcnf $config_g && readcnf $config_l




##create/clean tmp folder
[ ! -d $tmp ] && mkdir $tmp || [ $cleantmp = 'y' ] && rm -rf $tmp/*
[ ! -d $chunks ] && mkdir $chunks || [ $cleanchunks = 'y' ] && rm -rf $chunks/*
[ ! -d $data ] && mkdir $data || [ $cleandata = 'y' ] && rm -rf $data/*

echo $(gettime)" Fetching variation and phenotypes..."
if [ $testrun = y ];then
	perl $bin/biomart_xml_query.pl $queries/v2p_test.xml | sort | uniq >$data/source_v2p
else
	perl $bin/biomart_xml_query.pl $queries/v2p.xml | sort | uniq >$data/source_v2p
fi
wait

echo '****************Result****************'
for result in $(find $data -type f); do
	echo  $result Count:`wc -l $result | cut -d ' ' -f1`
	head -2 $result
	echo ...
	echo '#############################################################'
done
#name='variation';
#des='ensembl variation database'
#link='http://www.ensembl.org/info/genome/variation/index.html'
source_id="$(perl $scripts/create_source.pl $db $host $user $psw)"
echo $(gettime)" Updating db..."
mysqlimport -h $host -u $user -p$psw --delete -L $db $data/source_v2p

exit 0;
if [ $checkupdate = 'y' ];then 
	echo "[$(date +"%T %D")] Fetching variation and phenotypes from ensembl..."
	for i in `perl  $scripts/fetch_variationsets.pl`
	do
		perl $scripts/fetch_variation.pl $i $testrun >$chunks/$i & 
	done
	echo "[$(date +"%T %D")] Waiting..."
	wait
	echo "[$(date +"%T %D")] Joining result..."
	for line in $(find $chunks -type f); do 
			cat $line >> $tmp/variation_raw
	done
	#rs5370	6	12296255	12296255	OMIM	MIM:131240	2747	HIGH DENSITY LIPOPROTEIN CHOLESTEROL LEVEL QUANTITATIVE TRAIT LOCUS 7
	grep '^rs' $tmp/variation_raw | awk -F "\t" '{ print $1"\t"$7"\t"$8"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' > $tmp/variation 
	echo "[$(date +"%T %D")] Done!"
else
	echo "[$(date +"%T %D")] checkupdate is off!"
fi

if [ $domapping = 'y' ];then 
	echo "[$(date +"%T %D")] Start NCBO mapping"
	sh $mapping_ncbo_path/hdo/run.sh -i $tmp/variation -o $tmp/v2d 
else
	echo "[$(date +"%T %D")] domapping is off!"
fi

exit 0;
