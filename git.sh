git pull
echo -n "Enter commit comment > "
read text
git add .
git commit -m "$text"
git push 
