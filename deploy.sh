yarn
git init
git config --global user.name "huke"
git config --global user.email "13602547696@163.com"
rm -rf public
git submodule update --init 
node_modules/.bin/hexo g

rm -rf gh-pages
git clone https://github.com/canxuemianbao/blog.git -b gh-pages gh-pages
cp -af public/. gh-pages 
cd gh-pages
git add .
git commit -m "Site updated: `date +"%Y-%m-%d %H:%M:%S"` UTC+8"
git push origin gh-pages