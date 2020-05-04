---
title: "Algorithm Count One"
date: 2020-05-04T20:13:45+08:00
draft: true
---
# 统计小于 n 的数字中 1 的个数

```javascript
/**
  * 分别统计 个位/十位/百位...含 1 的个数
  */
function countOne(n) {
  let sum = 0, m = 10, digit = 0, length = n.toString().length
  while(digit < length) {
    let x = Math.floor(n / m)
    let y = n % m
    let z = Math.floor(y / (10**digit))
    if (z > 1) {
      sum += (x + 1) * 10**digit
    } else if (z === 1) {
      sum += x * 10**digit + y - 10**digit + 1
    } else {
      sum += x * 10**digit
    }
    m *= 10
    digit++
  }
  return sum
}
```
