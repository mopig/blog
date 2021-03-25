---
title: "前端开发环境 - Mac 篇"
date: 2021-03-25T11:30:45+08:00
categories: ["技术", "工具"]
tags: ["前端开发", "环境配置", "macOS"]
Description: "算法，计算机，it，统计小于 n 的数字中 1 的个数，algorithm"
---

## 工具列表

- `iTerm2` - 终端
- `VS Code` - 编辑器
- `Chrome` - 浏览器
- `ClashX` - 网络工具
- `Alfred` - 效率工具
- `Dash` - 开发文档工具
- `Paw` - 接口调试工具
- `SwitchHosts!` - 管理 host
- `TablePlus` - 数据库工具
- `Charles` - 网络代理工具
- `uPic` - 上传图片工具

## 基于 iTerm2 的命令行配置

1. 安装 `brew` - macOS 包管理工具

```sh
export HOMEBREW_BREW_GIT_REMOTE="..."  # put your Git mirror of Homebrew/brew here
export HOMEBREW_CORE_GIT_REMOTE="..."  # put your Git mirror of Homebrew/homebrew-core here
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
```
参考链接：[Homebrew](https://docs.brew.sh/Installation)

2. `antigen` - zsh 插件管理工具

  - `antigen` 安装：

```sh
brew install antigen
```

  - `antigen` 基本配置：

```sh
# 写入 .zshrc
source /path-to-antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle heroku
antigen bundle pip
antigen bundle lein
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme robbyrussell

# Tell Antigen that you're done.
antigen apply
```

3. Powerlevel10k - zsh theme

```sh
# 编辑 .zshrc 注意注释其他主题
antigen theme romkatv/powerlevel10k
```

4. Node.js 相关包

- `yarn` - `brew` 安装
- `nvm` - 通过 `antigen` 插件集成
- `nrm` - `yarn` 全局安装
- `pnpm` - `yarn` 全局安装

## 效果图

![iTerm2 效果图](https://cdn.jsdelivr.net/gh/mopig/oss@master/uPic/202103/Screen Shot 2021-03-25 at 17.45.42.png)
