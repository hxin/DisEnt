git pull
echo -n "Enter commit comment > "
read text
git add .
git commit -a -m "$text"
git push 
