#!/bin/bash
BASEDIR=$(dirname $0)
$CHUNK=$BASEDIR/tmp/chunks
$IN=$BASEDIR/gf
$OUT=$BASEDIR/out

[ ! -d $BASEDIR/tmp ] && mkdir $BASEDIR/tmp;
echo "[$(date +"%T %D")] Start chunking files..."
echo "[$(date +"%T %D")] Create/Empty chunk folder..."
( [ -d $CHUNK ] && rm -f $CHUNK/* ) || mkdir $BASEDIR/tmp/chunks;
echo "[$(date +"%T %D")] Chunking file..."
(cp $IN $CHUNK/source && cd $CHUNK && split -n l/$NCBO_CHUNK_NUMBER -a 3 -d ./source chunk_ && rm -f ./source)
#ls $CHUNK
echo "[$(date +"%T %D")] Start NCBO mapping..."
for line in $(find $CHUNK -iname 'chunk_*'); do 
	perl $BASEDIR/ncbo.pl $line * &
done
echo "[$(date +"%T %D")] Waiting for process to be finished..."
wait
echo "[$(date +"%T %D")] Finish!"
echo "[$(date +"%T %D")] Joining result..."
for line in $(find $CHUNK -iname 'chunk_*_parsed'); do 
	cat $line >> $CHUNK/all
done
cp $CHUNK/all $OUT



exit;

#[ $# -eq 0 ] && echo No arugments supplied! && exit 1;



usage="map_source.sh [OPTIONS] INPUT OUTPUT"

while [ "$1" != "" ]; do
    case $1 in
        -f | --file )           shift
                                filename=$1
                                ;;
        -i | --interactive )    interactive=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done