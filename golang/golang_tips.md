
## go mod

### import gitlab private repo

```
git config url."ssh://git@private.repo.net".insteadOf "https://private.repo.net"
```

或者编辑项目.git/config文件，增加

```
...
[url "ssh://git@private.repo.net"]
      insteadOf = https://private.repo.net
```

编辑代码import部分

```
instead

import "private.repo.net/user/package/a"

with

import "private.repo.net/user/package.git/a"
```

参考 https://github.com/golang/go/issues/27254

### replace

golang.org/x with github.com/golang/x

## 
