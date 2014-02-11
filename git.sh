git pull
echo -n "Enter commit comment > "
read text

if [ -n "$text" ]; then
echo "commment: $text"
else
    text=#
fi
git add .
git commit -a -m "$text"
git push
echo 'done'
