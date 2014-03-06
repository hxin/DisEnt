#!/bin/sh
##########################################
### This script is used to create the HDO tables.
##########################################
BASEDIR=$(dirname $0)

functions=$BASEDIR/../../common/functions.sh
scripts=$BASEDIR/scripts
tmp=$BASEDIR/tmp
chunks=$tmp/chunks
data=$BASEDIR/data

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
[ ! -d $chunks ] && mkdir $chunks || rm -rf $chunks/*
[ ! -d $data ] && mkdir $data


echo $(gettime)" Checking update..."
( [ -n "$(cd $data; wget -nv -N --spider $hdo_url 2>&1 | grep '200 OK')" ] && exit 1; exit 0; )

##1 needs update, 0 don't.
need_update=$?

##download new file
[ $testrun = 'n' ] &&[ $need_update -eq 0 ] && echo $(gettime)"	You are using the lastest HDO data!" && exit 0

echo $(gettime)" Update available..."; 
echo $(gettime)" Fetching from $hdo_url..." 
(cd $data/ && wget -nv -N $hdo_url);

echo $(gettime)" Parsing..."
cp $data/doid.obo $tmp/doid.obo
#(cp $tmp/doid.obo $chunks && cd $chunks && head -100 doid.obo | awk -F ":" '/^id:/ {fn=$3 ".term"} /^\[Term\]/ {fn=0} fn {print > fn} ')
ontology_id="$(perl $scripts/create_ontology.pl $db $host $user $psw)"
		#for line in $(find $chunks -iname '*.term'); do 
		    #    perl $scripts/createdb.pl $db $host $user $psw $line
		#done		
cat $tmp/doid.obo | perl $scripts/do_terms.pl >$data/ontology_term
#add ontology id
perl -i -pe "s/^/$ontology_id\t/" $data/ontology_term;
cat $tmp/doid.obo | perl $scripts/do_term2term.pl >$data/ontology_term2term
cat $tmp/doid.obo | perl $scripts/do_do2synonyms.pl >$data/ontology_term_synonym
cat $tmp/doid.obo | perl $scripts/do_do2xrefs.pl >$data/ontology_term_dbxref
cat $tmp/doid.obo | perl $scripts/do_do2altid.pl >$data/ontology_term_altid


echo '****************Result****************'
for result in $(find $data -type f -iname 'ontology_*'); do
	echo  $result Count:`wc -l $result | cut -d ' ' -f1`
	head -2 $result
	echo ...
	echo '#############################################################'
done


echo $(gettime)" Updating db..."
mysqlimport -h $host -u $user -p$psw --delete -L $db $tmp/ontology_term
mysqlimport -h $host -u $user -p$psw --delete -L $db $tmp/ontology_term2term
mysqlimport -h $host -u $user -p$psw --delete -L $db $tmp/ontology_term_synonym
mysqlimport -h $host -u $user -p$psw --delete -L $db $tmp/ontology_term_dbxref
mysqlimport -h $host -u $user -p$psw --delete -L $db $tmp/ontology_term_altid
exit 0;
