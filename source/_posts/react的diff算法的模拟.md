---
title: 写一个react：实现react diff算法
date: 2019-05-7
---
## react diff算法的简介
> React基于两点假设，实现了一个启发的O(n)算法：
> 1. 两个不同类型的元素将产生不同的树。
> 2. 开发者可以使用key属性来提示哪些子元素是稳定的。


 <img src="http://pqpdgd2yx.bkt.clouddn.com/blog/tree_diff.jpg" width = "400" height = "300" alt="坐标轴" align=center />

本质上其实很简单，react只对比同层同类型的节点。如图中每个颜色对应的部分。

## 理论
如果想要实现这个需求，我们需要首先了解react节点的基本内部结构，即vnode（react的虚拟dom的格式）以及component（提供render方法来产生虚拟dom）这两种节点。
其中vnode的数据结构大概长成这样(实际中的tag字段其实是type字段)：
```
{tag: "div", attrs: null, children: Array(0)}
```
而component的数据结构长成这样：
```
{tag: ƒ, attrs: null, children: Array(0)}
```
区别在于component的tag是一个function，也就是render方法，而普通的vnode的tag则是节点的类型。

想要实现diff算法则是需要实现dom结构/旧的virtual dom结构与新virtual dom结构的每一层的对比（上图），并且应用到真正的dom结构里面，来实现部分render。
react之前的实现（在fiber之前）是通过中序遍历来对比节点的，这里分3种类型的对比：
1. 两个节点本身的对比
2. component的对比
3. 子节点的对比（主要是为了排序）

### 两个节点本身的对比
当比较两个相同类型的React DOM元素时，React则会观察二者的属性(attributes)，保持相同的底层DOM节点，并仅更新变化的属性。例如：
```
<div className="before" title="stuff" />
<div className="after" title="stuff" />
```
通过比较这两个元素，React知道仅更改底层DOM元素的className。
在处理完DOM元素后，React递归其后代。
简易代码实现：
```
function diffNode(dom, vnode) {
  diffAttributes(dom, vnode);

  if (vnode.children && vnode.children.length > 0 || (out.childNodes && out.childNodes.length > 0)) {
    diffChildren(dom, vnode.children);
  }

  return dom;
}
```

### component的对比
当中序遍历遇到了component的时候，react会判断这上一次的dom是否是这一次component的类型，如果是的话就调用setComponentProps把props传给component，否则就完全销毁上一个component（如果有的话），然后重新创建一个component。
```
function diffComponent(dom, vnode) {
  // _component记录了上一个dom的component

  const c = dom && dom._component;
    // 如果上一个dom的component存在并且类型和新的component一致的话就改变它的props
    // 将新的props传给component

    setComponentProps(c, vnode.attrs);
  } else {
    // 不一致的话则重新生成新的component

    if (c) {
      unmountComponent(c);
    }
    // 创建component，并且走它的生命周期

    const newComponent = createComponent(vnode.tag, vnode.attrs);
    setComponentProps(newComponent, vnode.attrs);
    if (dom) {
      dom._component = null;
      removeNode(dom);
    }
    dom = newComponent.base;
  }
  return dom;
}

function renderComponent(component) {
  let base;
  if (component.base) {
      component.componentWillUpdate();
  }
  base = diffNode(component.base, component.render());
  if (!component.base) {
      component.componentDidMount();
  } else {
      component.componentDidUpdate();
  }

  component.base = base;
  base._component = component;
}

function createComponent(component, props) {
  if (component.prototype && component.prototype.render) {
    return new component(props);
  } else {
    const inst = {};
    inst.constructor = component;
    inst.render = function() {
      return this.constructor(props);
    }
  }
}

// componentWillMount componentWillReceiveProps
function setComponentProps(component, props) {
  if (!component.base) {
      component.componentWillMount();
  } else {
      component.componentWillReceiveProps(props);
  }
  renderComponent(component);
}
```

注意，如果两个component类型不一致，它们的内容一样也会被完全替代，如图：

 <img src="http://pqpdgd2yx.bkt.clouddn.com/blog/component_diff.jpg" width = "400" height = "300" alt="坐标轴" align=center />

### 子节点的对比
子节点递归会有3种情况：
1. 子节点提供了key，则按照key相同的先比较
2. 没有提供key的按照类型相同的进行比较
3. 完全不同的则就地创建新节点

而在最后则会删除那些不需要的旧节点。

```
function diffChildren(dom, vchildren) {
  const domChildren = dom.childNodes;
  const children = [];

  const keyed = {};

  // 将有key的节点和没有key的节点分开
  if (domChildren.length > 0) {
    for (let i = 0; i < domChildren.length; i++) {
      const child = domChildren[i];
      const key = child.key;
      if (key) {
        keyed[key] = child;
      } else {
        children.push(child);
      }
    }
  }

  for (let i = 0; i < vchildren.length; i++) {
    const vnode = vchildren[i];
    let child;
    if (vnode.key != undefined && vnode.key === keyed[key]) {
      child = keyed[key];
      keyed[key] = undefined;
    } else {
      for (let j = 0; j < children.length; j++) {
        if (children[j] != undefined && isSameNodeType(children[j], vnode)) {
          child = children[j];
          children[j] = undefined;
          break;
        }
      }
    }

    // 原来就有的节点会就地改变，而如果child为undefined的话则会创造新的节点，vnode不会是undefined
    const out = diffNode(child, vnode);
    const currentDom = dom.childNodes[i];
    if (out !== currentDom) {
      dom.insertBefore(out, currentDom);
    }
  }

  const pendingLength = dom.childNodes.length;
  for (let i = vchildren.length; i < pendingLength; i++) {
    dom.removeChild(dom.childNodes[vchildren.length]);
  }
}
```

## 实现
这边的实现参考了[从零开始实现一个React](https://github.com/hujiulong/simple-react/tree/master)的例子，自己fork了它，并且从第一章开始重新写。
这边可以拉一下我的分支来本地跑跑，git clone https://github.com/canxuemianbao/simple-react/tree/diff， `yarn start`即可。

 <img src="http://pqpdgd2yx.bkt.clouddn.com/blog/react_diff.gif" width = "900" height = "600" alt="坐标轴" align=center />

如图，只有文字被浏览器发现修改了。

## 总结
目前只是将理论应用到了代码里面，大部分是参考别人的实现==，但是大方向是没有问题的。下一步可以是围观react的真正实现，也可以是继续按照原理实现fiber和异步state，看看哪一步走不下去了就换一个方向吧~，在之后会完善本篇博客，使其更容易阅读。

## 参考
[从零开始实现一个React](https://github.com/hujiulong/blog/issues/6)
[react reconciliation](https://react.docschina.org/docs/reconciliation.html)
[React 源码剖析系列 － 不可思议的 react diff](https://zhuanlan.zhihu.com/p/20346379)