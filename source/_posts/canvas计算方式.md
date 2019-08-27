---
title: canvas移动/缩放/旋转的常用计算方式
date: 2019-04-30
---
## 简介
  canvas2d的坐标移动，旋转，和缩放基本都是通过对画布而不是要画的物体本身进行操作的，在这里记录一下计算方式，免得每次都忘记。

 <img  src="http://hukeblog.cn/blog/coordinate.png" width = "400" height = "300" alt="坐标轴" align=center />

## 移动
  想要让物体中心移动坐标点为x, y的位置，可以这么画：
  
 <img src="http://hukeblog.cn/blog/translate1.png" width = "400" height = "300" alt="移动" align=center />
## 旋转
  如果想要先移动再到x，y，再顺时针旋转angle度的话，可以这么画：

 <img src="http://hukeblog.cn/blog/rotate.png" width = "400" height = "300" alt="移动+旋转" align=center />
 <img src="http://hukeblog.cn/blog/draw_translate_and_rotate.png" width = "400" height = "300" alt="移动+旋转" align=center />
## 缩放
  改变比例的话可以这么画（记住画布翻转过后里面的东西也是翻转的）：

 <img src="http://hukeblog.cn/blog/flip.png" width = "400" height = "300" alt="翻转" align=center />
 <img src="http://hukeblog.cn/blog/draw_flip.png" width = "400" height = "300" alt="翻转" align=center />
## transform
  transfrom基本公式为：
  ```
  ctx.transform(a, b, c, d, e, f);
  ```
  <img src="http://hukeblog.cn/blog/matrix.png" width = "400" height = "200" alt="翻转" align=center />
  transform为更高级的特性，能够免去很多手动计算，比如上面的各种情况用transform来画就是：

  ```
  // 只移动
  ctx.transform(1, 0, 0, 1, x + width / 2, y + height / 2);
  ctx.drawImage(img, -width / 2, -height / 2);
  ```

  ```
  // 图片中心点移动到(x, y)后旋转angle度
  ctx.transform(
    Math.cos(angle), Math.sin(angle),
    -Math.sin(angle), Math.cos(angle),
    x + width / 2, y + height / 2);
  ctx.drawImage(img, -width / 2, -height / 2);

  // 图片左上角点围绕某个点(x1, x2)旋转
  ctx.transform(
    Math.cos(angle), Math.sin(angle),
    -Math.sin(angle), Math.cos(angle),
    - Math.cos(angle) * x1 + Math.sin(angle) * y1 + x1 , - Math.sin(angle) * x1 - Math.cos(angle) * y1 + y1);
  ctx.drawImage(img, 0, 0);
  ```


## 参考
[凹凸实验室](https://aotu.io/notes/2017/05/25/canvas-img-rotate-and-flip/index.html)