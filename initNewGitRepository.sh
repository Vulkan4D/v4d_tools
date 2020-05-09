cd `dirname $0`/..
git remote remove origin
current=`git branch --show-current`
git checkout --orphan _newproject
git add -A
git commit -m'initial commit'
git branch -D $current
git branch -m master
