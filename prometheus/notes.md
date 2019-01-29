
## 指标类别

- counter (累加指标)
- gauge (测试指标)
- summary (概略图)
- histogram (直方图)

## counter

Counter类型只允许单调递增(正如其名字一样,这是一个只能进行加操作的计数器).其绝对禁止进行减操作,但可以被重置(比如服务被重新启动) Counter拥有下列两个函数:

Counter必须从0开始计数.

```
inc():对计数器加1
inc(v float64):对计数器加v,v>=0
```

## gauge

Gauge在Counter的基础上,取消了单调递增的限制,允许增加或减少,以及直接设置.

```
inc(): 进行加1操作
inc(v double): 进行加v操作
dec(): 进行减1操作
dec(v double): 进行减v操作
set(v double): 将gauge的值设置为v
```
