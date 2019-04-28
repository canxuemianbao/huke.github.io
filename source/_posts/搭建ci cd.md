---
title: 通过circle ci和hexo搭建自己的博客
---

## 动机
一开始是打算搭一个自己博客，然后突然又想了解一下ci的部署流程，就顺手一起搭了。看到git push后1分钟左右刷新页面有了变化还是比较有成就感滴。
整个原理很简单：
1. 通过github托管blog项目，master是项目文件，gh-pages分支是博客的html文件
2. 通过github pages来部署网站
3. 通过circle ci来执行配置环境，推代码一系列操作
4. 以后push markdown文件到master就可以实现自动部署啦。
## 技术
### github
  push -f 一个分支到git-page（或者随便起的什么名字里面）, 然后到项目的setting里面把它设置为博客的分支。
### hexo
  熟悉3个命令，hexo clean（清除博客文件），hexo g（生成博客文件）。
### circle ci
#### 关联github账号
登录circle ci官网，signup的时候会弹出来让你关联github，一路确认就行
#### 配置ssh以便使circle ci有推代码到github上的权限
将生成的ssh或者已经有的ssh key的private key放到circle ci上面，public key放到github上面。

#### 编写config.yml

``` bash
version: 2
jobs:
  build:
    docker: # use the docker executor type; machine and macos executors are also supported
      - image: circleci/node:latest # the primary container, where your job's commands are run
    working_directory: ~/blog
    steps:
      - checkout # check out the code in the project directory
      - add_ssh_keys:
          fingerprints:
            - "你自己的ssh fingerprints"
      - run: bash deploy.sh

workflows:
  version: 2
  main:
    jobs:
      - build:
          filters:
            branches:
              only: master
```

deploy.sh 内容如下
``` bash
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
```

创建.circleci，放到master和gh-pages的根目录下，然后把config.yml放到.circleci下就行。之所以要放在gh-pages下是为了避免ci每次再去部署一遍gh-pages，上面的workflows里面注明了只跑master。

deploy.sh跑了一些自定义脚本，这里我做的事情很简单，就是把博客的分支 clone下来，通过hexo g生成新的博客页面并且拷贝到这个branch里面，然后再git push到博客的分支。


## 小tips
1. 拷贝一个文件夹下的所有东西到另一个文件夹里面，在mac上cp -a test1/ test2就行，在linux下必须要cp -a test1/. test2才行
2. 把主题(hexo-themes-next)作为submodule，这样不需要每次上传这些特别大的主题，然后如果有ci的话，本地也不需要生成或者下载这些也别大的主题，ci这边跑跑git submodule update --init就好

## 参考
[hexo](https://hexo.io/zh-cn/docs/index.html)

[circle ci](https://circleci.com/)

[创建ssh key](https://git-scm.com/book/zh/v1/%E6%9C%8D%E5%8A%A1%E5%99%A8%E4%B8%8A%E7%9A%84-Git-%E7%94%9F%E6%88%90-SSH-%E5%85%AC%E9%92%A5)

[博客](https://halu.lu/post/auto-deploy-with-circleci/)