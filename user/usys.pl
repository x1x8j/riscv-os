#!/usr/bin/perl -w

# 生成 usys.S 文件，系统调用的桩代码

print "# 由 usys.pl 生成 - 请勿编辑\n";

print "#include \"kernel/syscall.h\"\n";

# 定义一个函数，用于生成每个系统调用的汇编代码
sub entry {
    my $prefix = "sys_";   # 系统调用的前缀
    my $name = shift;      # 系统调用的名称
    if ($name eq "sbrk") {  # 对于sbrk特殊处理
        print ".global $prefix$name\n";   # 全局符号，sbrk
        print "$prefix$name:\n";          # sbrk函数标签
    } else {
        print ".global $name\n";          # 对于其他系统调用，直接定义全局符号
        print "$name:\n";                 # 系统调用标签
    }
    # 设置系统调用号
    print " li a7, SYS_${name}\n";   # 将系统调用号加载到 a7 寄存器
    print " ecall\n";                 # 执行系统调用
    print " ret\n";                   # 返回
}
	
# 为每个系统调用生成汇编代码
entry("fork");     # 创建进程
entry("exit");     # 退出进程
entry("wait");     # 等待进程
entry("pipe");     # 创建管道
entry("read");     # 读取文件
entry("write");    # 写入文件
entry("close");    # 关闭文件
entry("kill");     # 终止进程
entry("exec");     # 执行程序
entry("open");     # 打开文件
entry("mknod");    # 创建设备节点
entry("unlink");   # 删除文件
entry("fstat");    # 获取文件状态
entry("link");     # 创建文件链接
entry("mkdir");    # 创建目录
entry("chdir");    # 改变工作目录
entry("dup");      # 复制文件描述符
entry("getpid");   # 获取进程ID
entry("sbrk");     # 分配内存
entry("pause");    # 暂停进程
entry("uptime");   # 获取系统运行时间
entry("dump_proc");
