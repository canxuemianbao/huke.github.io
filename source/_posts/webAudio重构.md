---
title: 重构audio引擎中设计模式的应用
date: 2019-04-29
---
## 简介

原来的audio标签不仅太卡顿了，缓存由浏览器控制，而且还没有立体声，对于3d游戏的应用场景不能忍。因此我们打算使用webaudio对它进行重构，webaudio是一个更底层，操纵性更好的api（虽然兼容性和audio标签一样蛋疼==），应用在3d游戏里面显然更加合适。写它的过程中用到了一些设计模式，拿出来分享一下。

## 大概的文件结构
![avatar](http://pqpdgd2yx.bkt.clouddn.com/blog/WechatIMG7.png)
## 需求
我们需要使用webaudio作为底层api，封装一个音效和背景音乐播放器。因此有一个source.ts文件用于做最基本的webaudio封装，它其实就已经是一个音乐播放器了，effectPlayer则是装饰了source.ts的音效播放器。

### 单例模式和简单工厂模式

source.ts
```
class AudioSource {
  private static _audioContext:AudioContext;

  private constructor(src:string, context:AudioContext, buffer:AudioBuffer, options:AudioOptions = {}) {

  }

  // _audioContext为单例，因为多个audioSource会使用同一个AudioContext
  public static getAudioContext() {
    if (AudioSource._audioContext === undefined) {
      AudioSource._audioContext = new AudioContext();
    }
    return AudioSource._audioContext;
  }

  // 简单工厂，隐藏了复杂的创建过程：javascript不能够使用异步构造函数，因此将创建过程隐藏到build方法内部。
  public static async build(src:string, options?:AudioOptions) {
    const audioContext = AudioSource.getAudioContext();

    const getBuffer = async () => {
      const arrayBuffer = await fetch(src, {method:'get'}).then((response) => response.arrayBuffer());
      const waitForDecode = new Promise<AudioBuffer>((resolve, reject) => audioContext.decodeAudioData(arrayBuffer, resolve, reject));
      const audioBuffer = await waitForDecode;
      return audioBuffer;
    };
    const audioSource = new AudioSource(src, audioContext, await getBuffer(), options);
    return audioSource;
  }

  // 播放音乐
  public tick() {
    ....
  }
}
```
写代码的时候发现需要异步构建source类，然而是没有办法直接new 一个source出来的，用init的方法来初始化对于使用者来说又特别繁琐。于是想着换种思维：把AudioSource本身当成一个AudioSource的工厂，通过build方法生成了一个AudioSource对象，这样使用者的体验就会变好（我原来要new完了再调用异步init，现在不用啦）。而文档又推荐了AudioContext整个页面应该只有一个，于是顺利成章的在这里使用了单例模式。

### 装饰器模式/原型模式/对象池模式
这里之所以要用到这么多模式是因为一个新的需求：音效播放器。
音乐播放器在适配了浏览器之后非常好用，然而。。。。
如果同时要播放多个声音怎么办？？？
多个玩家一起跳，就应该有多个声音呀，然而如果每个玩家都创建一个音效对象又过于浪费，buffer很大滴。
于是很显然，对象池在这里就是一个好的解决办法，那么自然而然的就需要有一个clone方法，方便在对象池里添加新对象。而又将这一切东西放在一个新的对象里面，同时也可以继续使用原来的音乐播放器作为底层，装饰器模式就派上用场啦！

source.ts
```
class AudioSource {
  ......

  // 原型模式，直接clone
  public clone(withState = false) {
    if (withState) {
      return new AudioSource(this.src, AudioSource.getAudioContext(), this.buffer, this.getState());
    }
    return new AudioSource(this.src, AudioSource.getAudioContext(), this.buffer, this.initialState);
  }

  public setState(state:AudioOptions) {
    if (state.playStatus != null) {
      this.diff.playStatus = state.playStatus;
    }
    if (state.distance != null) {
      this.diff.distance = state.distance;
    }
  }

  public tick() {
    if (this.diff.distance != null && !vec3.equals(this.diff.distance, this._distance)) {
      this.distance(this.diff.distance);
    }
    if (this.diff.playStatus != null && this.diff.playStatus !== this._playStatus) {
      if (this.diff.playStatus === PlayStatus.playing) {
        this.play(this._seek);
      } else if (this.diff.playStatus === PlayStatus.paused) {
        this.pause();
      } else {
        this.stop();
      }
    }
    this.diff = {};
  }
}
```

effectPlayer.ts

```
// 对象池模式，用于存储多个同时发生的音效
class Pool {
  private soundPrototype:AudioSource;
  private unUsed:AudioSource[] = [];
  private capacity = 0;
  public constructor(sound:AudioSource, capacity:number) {
    this.soundPrototype = sound;
    this.capacity = capacity;
    while (this.unUsed.length < capacity) {
      this.unUsed.push(sound.clone());
    }
  }

  public alloc() {
    return this.unUsed.pop() || this.soundPrototype.clone();
  }

  public returnToPool (sound:AudioSource) {
    if (this.unUsed.length < this.capacity) {
      this.unUsed.push(sound);
    }
  }
}

// 装饰器模式，封装了AudioSource
class EffectPlayer {
  private currentSounds:AudioSource[] = [];
  private pool:Pool;
  constructor(sound:AudioSource, capacity:number) {
    this.pool = new Pool(sound, capacity);
  }

  public play(state:AudioOptions) {
    const sound = this.pool.alloc();
    state = Object.assign({playStatus:PlayStatus.playing}, state);
    sound.setState(state);
    this.currentSounds.push(sound);
  }

  public tick() {
    const newCurrentSounds:AudioSource[] = [];
    for (let i = 0; i < this.currentSounds.length; i++) {
      const currentSound = this.currentSounds[i];
      currentSound.tick();
      const playStatus = currentSound.getState().playStatus;
      if (playStatus === PlayStatus.stop) {
        this.pool.returnToPool(currentSound);
      } else {
        newCurrentSounds.push(currentSound);
      }
    }
    this.currentSounds = newCurrentSounds;
  }
}
```
