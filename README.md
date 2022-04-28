# fix-import

* 近期在清理`pch`所以随便糊糊了一个小工具
* 根据符号自动导入头文件

```shell
fix-import --help

USAGE: fix-import --src <src> --import <import> --symbol-pattern <symbol-pattern> [--header]

OPTIONS:
  -s, --src <src>         源码目录
  -i, --import <import>   import 文件
  --symbol-pattern <symbol-pattern>
                          符号正则, 用于匹配 import 文件中的符号
  --header                是否仅处理头文件
  -h, --help              Show help information.
```
* 例如某些头文件依赖了 `UIButton`,需要补齐
```shell
fix-import --src xxx --import "<UIKit/UIButton.h>" --symbol-pattern "UIButton" --header
```
* 再例如实现文件依赖了某些文件,需要补齐
```shell
fix-import --src xxx --import "<QMUIKit/QMUIButton.h>" --symbol-pattern "\s[QMUIButton|QMUIButtonImagePosition"
```
