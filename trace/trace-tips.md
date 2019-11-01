# 概念介绍

## trace工具介绍

> ptrace: gdb和strace基于ptrace. ptrace有很多缺点，比如需要改变目标调试进程的父亲，还不允许多个调试者同时分析同一个进程. gdb在调试过程中设置断点会发出SIGSTOP信号，这会让被调试进程进入T（TASK_STOPPED or TASK_TRACED）暂停状态或跟踪状态.
> 动态追踪(dynamic-tracing): dtrace(solaris), systemtap(基于utrace,或者uprobes, uretprobes), perf(kprobes, uprobes), bcc(基于ebpf)

gdb注重交互性，适合离线调试，比如调试core dump
systemtap适合在线分析，对进程影响小
