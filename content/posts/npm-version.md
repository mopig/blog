---
title: "Npm Version"
date: 2020-05-04T19:23:01+08:00
---
# 关于 `npm version` 的使用

## 正常的版本更新

- 大版本更新（包含 `breaking change`）：`npm version major`
- 小版本更新（小的功能迭代）：`npm version minor`
- 补丁更新（bugfix）：`npm version patch`

## 预发布版本

`npm version premajor`，`npm version preminor` 和 `npm version preminor`。针对每一次版本更新，根据更新版本的不同，执行前面三个命令中的一个，后面在此版本继续更新时，只需要执行 `npm version prerelease`，例：

```shell
project-name|master ⇒ npm version prepatch
> v1.0.1-0
project-name|master ⇒ npm version prerelease
> v1.0.1-1
project-name|master ⇒ npm version patch # 结束预发版
> v1.0.1
```

可以通过 `--preid=<prerelease-id>` 指定预发版的关键词，例：

```shell
project-name|master ⇒ npm version preminor --preid=alpha
> v1.1.0-alpha.0
project-name|master ⇒ npm version prerelease
> v1.1.0-alpha.1
project-name|master ⇒ npm version minor
> v1.1.0
```

## 结合 `npm scripts`

```json
"scripts": {
  "preversion": "npm test",
  "version": "npm run build && git add -A dist",
  "postversion": "git push && git push --tags && rm -rf build/temp"
}
```

更多关于语义化版本的内容，请戳 [semver.inc][semver.inc ]

[semver.inc]: https://github.com/npm/node-semver#functions
