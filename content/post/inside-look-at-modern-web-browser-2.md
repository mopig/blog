---
title: '深入了解现代浏览器工作原理（二）「译」'
date: 2022-04-24T10:56:20+08:00
categories: ['技术', '浏览器', '原理', '翻译']
tags: ['Chrome', '浏览器', '浏览器原理', '翻译']
Description: '核心计算术语和 Chrome 的多进程架构'
---

### 导航中会发生什么

这是 4 部分博客系列的第 2 部分，该系列着眼于 Chrome 的内部工作原理。在上一篇文章中，我们研究了不同的进程和线程如何处理浏览器的不同部分。在这篇文章中，我们深入探讨了每个进程和线程如何进行通信以显示网站。

让我们看一个简单的网页浏览用例：你在浏览器中输入一个 URL，然后浏览器从互联网上获取数据并显示一个页面。在这篇文章中，我们将重点关注用户请求站点和浏览器准备呈现页面的部分——也称为导航。

### 它从浏览器进程开始

![浏览器进程](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/GSzlSm.jpg)
_图 1：顶部的浏览器 UI，底部包含 UI、网络和存储线程的浏览器进程图_

正如我们在第 1 部分：CPU、GPU、内存和多进程架构中介绍的那样，选项卡之外的所有内容都由浏览器进程处理。浏览器进程具有诸如绘制浏览器按钮和输入字段的 UI 线程、处理网络堆栈以从 Internet 接收数据的网络线程、控制对文件的访问的存储线程等线程。当您在地址栏中键入 URL 时，您的输入由浏览器进程的 UI 线程处理。

### 一个简单的导航

#### 第 1 步：处理输入

当用户开始在地址栏中输入内容时，UI 线程询问的第一件事是“这是搜索查询还是 URL？”。在 Chrome 中，地址栏也是一个搜索输入字段，因此 UI 线程需要解析并决定是将您发送到搜索引擎还是您请求的站点。

![处理用户输入](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/A5eTW5.jpg)
_图 1：UI 线程询问输入是搜索查询还是 URL_

#### 第 2 步：开始导航

当用户点击回车时，UI 线程会发起网络调用以获取站点内容。加载微调器显示在选项卡的一角，网络线程通过适当的协议，如 DNS 查找和为请求建立 TLS 连接。

![导航开始](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/Of6NdY.jpg)
_图 2：UI 线程与网络线程对话以导航到 mysite.com_

此时，网络线程可能会收到 HTTP 301 之类的服务器重定向标头。在这种情况下，网络线程会与服务器正在请求重定向的 UI 线程通信。然后，将发起另一个 URL 请求。

#### 第 3 步：阅读回复

![HTTP 响应](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/7wMUX8.jpg)
_图 3：包含 Content-Type 的响应头和作为实际数据的有效负载_

一旦响应主体（有效负载）开始进入，网络线程会在必要时查看流的前几个字节。响应的 Content-Type 标头应该说明它是什么类型的数据，但由于它可能丢失或错误，因此在这里进行 [MIME 类型嗅探](https://developer.mozilla.org/docs/Web/HTTP/Basics_of_HTTP/MIME_types)。[如源代码](https://cs.chromium.org/chromium/src/net/base/mime_sniffer.cc?sq=package:chromium&dr=CS&l=5)中所述，这是一项“棘手的业务” 。您可以阅读评论以了解不同的浏览器如何处理内容类型/有效负载对。

如果响应是一个 HTML 文件，那么下一步就是将数据传递给渲染器进程，但如果它是一个 zip 文件或其他文件，那么这意味着它是一个下载请求，所以他们需要将数据传递给下载管理器。

![MIME 类型嗅探](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/Ya3VJK.jpg)
_图 4：网络线程询问响应数据是否是来自安全站点的 HTML_

这也是进行安全浏览检查的地方。如果域和响应数据似乎与已知的恶意站点相匹配，则网络线程会发出警报以显示警告页面。此外，发生跨源读取 B 锁定(CORB )检查是为了确保敏感的跨站点数据不会进入渲染器进程。

#### 第 4 步：查找渲染器进程

一旦完成所有检查并且网络线程确信浏览器应该导航到请求的站点，网络线程就会告诉 UI 线程数据已准备好。UI 线程然后找到一个渲染器进程来进行网页的渲染。

![查找渲染器进程](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/rqNurT.jpg)
_图 5：网络线程告诉 UI 线程找到渲染器进程_

由于网络请求可能需要数百毫秒才能得到响应，因此应用了加速此过程的优化。当 UI 线程在第 2 步向网络线程发送 URL 请求时，它已经知道他们正在导航到哪个站点。UI 线程尝试主动查找或启动与网络请求并行的渲染器进程。这样，如果一切按预期进行，当网络线程接收到数据时，渲染器进程已经处于待机位置。如果导航重定向跨站点，则可能不会使用此备用进程，在这种情况下，可能需要不同的进程。

#### 第 5 步：提交导航

现在数据和渲染器进程已准备就绪，从浏览器进程向渲染器进程发送 IPC 以提交导航。它还传递数据流，因此渲染器进程可以继续接收 HTML 数据。一旦浏览器进程听到在渲染器进程中发生提交的确认，导航就完成了，文档加载阶段就开始了。

此时，地址栏更新，安全指示器和站点设置 UI 反映了新页面的站点信息。该选项卡的会话历史记录将被更新，因此后退/前进按钮将逐步浏览刚刚导航到的站点。为了在您关闭选项卡或窗口时促进选项卡/会话恢复，会话历史记录存储在磁盘上。

![提交导航](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/DRh1s5.jpg)
_图 6：浏览器和渲染器进程之间的 IPC，请求渲染页面_

#### 额外步骤：初始加载完成

提交导航后，渲染器进程会继续加载资源并渲染页面。我们将在下一篇文章中详细介绍此阶段发生的事情。一旦渲染器进程“完成”渲染，它会将 IPC 发送回浏览器进程（这是在 onload 页面中的所有帧上触发所有事件并完成执行之后）。此时，UI 线程停止选项卡上的加载微调器。

我说“完成”，因为在此之后客户端 JavaScript 仍然可以加载额外的资源并呈现新视图。

![页面完成加载](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/wk4gI7.jpg)
_图 7：从渲染器到浏览器的 IPC 进程通知页面已经“加载”_

### 导航到其他站点

简单的导航就完成了！但是如果用户再次将不同的 URL 放到地址栏会发生什么？好吧，浏览器进程通过相同的步骤导航到不同的站点。但在此之前，它需要检查当前呈现的站点是否关心 [`beforeunload`](https://developer.mozilla.org/docs/Web/Events/beforeunload) 事件。

`beforeunload` 可以创建“离开此站点？” 当您尝试离开或关闭选项卡时发出警报。选项卡内的所有内容，包括您的 JavaScript 代码，都由渲染器进程处理，因此当新的导航请求进来时，浏览器进程必须检查当前的渲染器进程。

> 警告：  
> 不要添加无条件 beforeunload 的处理程序。它会产生更多的延迟，因为处理程序需要在导航开始之前执行。仅在需要时才应添加此事件处理程序，例如，如果需要警告用户他们可能会丢失他们在页面上输入的数据。

![beforeunload 事件处理程序](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/b61Cky.jpg)
_图 8：从浏览器进程到渲染器进程的 IPC 告诉它它即将导航到不同的站点_

如果导航是从渲染器进程启动的（例如用户单击链接或客户端 JavaScript 已运行 window.location = "https://newsite.com"），则渲染器进程首先检查beforeunload处理程序。然后，它经历与浏览器进程启动导航相同的过程。唯一的区别是导航请求是从渲染器进程启动到浏览器进程的。

当新导航指向与当前呈现的站点不同的站点时，会调用一个单独的呈现进程来处理新的导航，而当前的呈现进程会被保留以处理诸如 unload. 有关更多信息，请参阅[页面生命周期状态概述](https://developers.google.com/web/updates/2018/07/page-lifecycle-api#overview_of_page_lifecycle_states_and_events)以及如何使用[页面生命周期 API](https://developers.google.com/web/updates/2018/07/page-lifecycle-api) 挂钩事件。

![新的导航和卸载](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/QalfkS.jpg)
_图 9：从浏览器进程到新渲染器进程的 2 个 IPC，告诉渲染页面并告诉旧渲染器进程卸载_

### 如果是 Service Worker

这个导航过程最近的一个变化是引入了[service worker](https://developers.google.com/web/fundamentals/primers/service-workers/)。Service Worker 是一种在应用程序代码中编写网络代理的方法；允许 Web 开发人员更好地控制本地缓存的内容以及何时从网络获取新数据。如果 Service Worker 设置为从缓存中加载页面，则无需向网络请求数据。

要记住的重要部分是服务工作者是在渲染器进程中运行的 JavaScript 代码。但是当导航请求进来时，浏览器进程如何知道站点有服务工作者？

![服务工作者范围查找](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/0s8VxB.jpg)
_图 10：浏览器进程中的网络线程查找 Service Worker 范围_

[注册 Service Worker 时，Service Worker 的范围作为参考保留（您可以在这篇 The Service Worker 生命周期](https://developers.google.com/web/fundamentals/primers/service-workers/lifecycle)文章中阅读有关范围的更多信息）。当导航发生时，网络线程会根据注册的服务工作者范围检查域，如果为该 URL 注册了服务工作者，UI 线程会找到一个渲染器进程以执行服务工作者代码。Service Worker 可以从缓存中加载数据，从而无需从网络请求数据，或者它可以从网络请求新资源。

![服务工作者导航](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/Q2dStC.jpg)
_图 11：浏览器进程中的 UI 线程启动渲染器进程来处理服务工作者；渲染器进程中的工作线程然后从网络请求数据_

### 导航预载

如果服务工作者最终决定从网络请求数据，您可以看到浏览器进程和渲染器进程之间的这种往返可能会导致延迟。[Navigation Preload](https://developers.google.com/web/updates/2017/02/navigation-preload) 是一种通过在服务工作者启动时并行加载资源来加速此过程的机制。它用标头标记这些请求，允许服务器决定为这些请求发送不同的内容；例如，仅更新数据而不是完整文档。

![导航预载](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202204/HwLdbZ.jpg)
_图 12：浏览器进程中的 UI 线程启动渲染器进程以处理服务工作者，同时并行启动网络请求_

### 包起来

在这篇文章中，我们研究了导航期间发生的情况以及您的 Web 应用程序代码（例如响应标头和客户端 JavaScript）如何与浏览器交互。了解浏览器从网络获取数据所经历的步骤，可以更容易地理解为什么要开发像导航预加载这样的 API。在下一篇文章中，我们将深入探讨浏览器如何评估我们的 HTML/CSS/JavaScript 以呈现页面。
