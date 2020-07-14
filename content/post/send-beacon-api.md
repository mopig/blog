---
title: "Navigator.sendBeacon API 异步发送数据"
date: 2020-07-15T01:02:01+08:00
categories: ["技术"]
tags: ["javascript", "unload", "sendBeacon"]
Description: "Navigator.sendBeacon API 异步发送数据"
---
## Syntax

```javascript
// data: ArrayBuffer, ArrayBufferView, Blob, DOMString, FormData, or URLSearchParams
navigator.sendBeacon(url, data)
```

## 场景

浏览器在触发 `unload` 事件时，会忽略异步请求，这样会导致一些需要发送统计数据的功能失效，在之前一般有以下三种方法解决这个问题：

- 在 `unload`、`beforeunload` 提交同步阻塞的 `XMLHttpRequest` 请求
- 在 `unload` 事件中，创建 `<img>` 并且设置 `src`，大部分浏览器会等到图片加载完成后再 `unload`
- 在 `unload`事件中创建一个耗时的 `no-op loop`

## 特性

- 发送数据可靠
- 异步操作，不阻塞
- 不影响加载下一个页面
- 简单可用（相对于之前对于一切场景的 hack）

