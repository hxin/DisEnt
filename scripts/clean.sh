BASEDIR=$(dirname $0)
find $BASEDIR -type d -iname tmp -exec rm -rf {} \;
exit 0;
