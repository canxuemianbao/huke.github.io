---
title: 实现一个异步compose方法
date: 2019-05-16
---

## 描述
现在有两个异步函数，希望能够按顺序异步执行它们
function add1(n, callback) {
  setTimeout(() => {
    callback(n + 1);
  }, 1000);
}

function mult3(n, callback) {
  setTimeout(() => {
    callback(n * 3);
  }, 1000);
}

compose(1, add1, mult3)
// 希望输出6 (1 + 1) * 3

## 实现
```
function add1(n, callback) {
  setTimeout(() => {
    callback(n + 1);
  }, 1000);
}

function mult3(n, callback) {
  setTimeout(() => {
    callback(n * 3);
  }, 1000);
}

function compose(n, ...funcs) {
  const createP = (func, value) => {
    return new Promise((resolve) => func(value, resolve));
  }
  let p = Promise.resolve(n);
  for (let i = 0; i < funcs.length; i++) {
    const func = funcs[i];
    p = p.then((v) => createP(func, v));
  }
  return p;
}

compose(1, add1, mult3).then(console.log);
```