git pull
now=$(date +"%T %D");
text='cron sync daily at $now'
git add .
git commit -a -m "$text"
git push
