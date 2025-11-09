//
// 文件系统系统调用。
// 主要进行参数检查，因为我们不信任用户代码，并调用 file.c 和 fs.c 中的函数。
//

#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "fcntl.h"

// 获取第n个系统调用参数作为文件描述符，并返回该描述符及对应的文件结构。
static int
argfd(int n, int *pfd, struct file **pf)
{
  int fd;
  struct file *f;

  argint(n, &fd);  // 获取系统调用参数中的文件描述符
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)  // 检查文件描述符的有效性
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
  return 0;
}

// 为给定文件分配一个文件描述符。
// 成功时接管调用者的文件引用。
static int
fdalloc(struct file *f)
{
  int fd;
  struct proc *p = myproc();

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){  // 查找一个未使用的文件描述符
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;  // 没有可用的文件描述符
}

uint64
sys_dup(void)
{
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  if((fd=fdalloc(f)) < 0)  // 为文件分配新的文件描述符
    return -1;
  filedup(f);  // 增加文件引用计数
  return fd;
}

uint64
sys_read(void)
{
  struct file *f;
  int n;
  uint64 p;

  argaddr(1, &p);  // 获取读取数据的用户空间地址
  argint(2, &n);  // 获取读取字节数
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  return fileread(f, p, n);  // 从文件中读取数据
}

uint64
sys_write(void)
{
  struct file *f;
  int n;
  uint64 p;
  
  argaddr(1, &p);  // 获取写入数据的用户空间地址
  argint(2, &n);  // 获取写入字节数
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;

  return filewrite(f, p, n);  // 向文件中写入数据
}

uint64
sys_close(void)
{
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  myproc()->ofile[fd] = 0;  // 关闭文件描述符
  fileclose(f);  // 关闭文件
  return 0;
}

uint64
sys_fstat(void)
{
  struct file *f;
  uint64 st; // 用户指针指向 struct stat

  argaddr(1, &st);  // 获取 stat 结构体地址
  if(argfd(0, 0, &f) < 0)  // 获取文件描述符并返回文件结构
    return -1;
  return filestat(f, st);  // 获取文件状态信息
}

// 创建新路径 new，作为指向与 old 相同 inode 的链接
uint64
sys_link(void)
{
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    return -1;

  begin_op();
  if((ip = namei(old)) == 0){  // 查找 old 路径对应的 inode
    end_op();
    return -1;
  }

  ilock(ip);
  if(ip->type == T_DIR){  // 如果是目录，不能创建链接
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;  // 增加链接计数
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)  // 获取 new 路径的父目录
    goto bad;
  ilock(dp);
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){  // 在父目录中创建新链接
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
  iput(ip);

  end_op();

  return 0;

bad:
  ilock(ip);
  ip->nlink--;  // 发生错误，恢复链接计数
  iupdate(ip);
  iunlockput(ip);
  end_op();
  return -1;
}

// 判断目录 dp 是否为空，除了 "." 和 ".." 外没有其他内容
static int
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){  // 跳过 "." 和 ".."
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)  // 如果目录项不为空
      return 0;
  }
  return 1;  // 目录为空
}

uint64
sys_unlink(void)
{
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)  // 获取路径
    return -1;

  begin_op();
  if((dp = nameiparent(path, name)) == 0){  // 查找路径的父目录
    end_op();
    return -1;
  }

  ilock(dp);

  // 不能删除 "." 或 ".."。
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)  // 查找目录项
    goto bad;
  ilock(ip);

  if(ip->nlink < 1)
    panic("unlink: nlink < 1");  // 检查链接计数
  if(ip->type == T_DIR && !isdirempty(ip)){  // 如果是非空目录，不能删除
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));  // 清空目录项
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))  // 删除目录项
    panic("unlink: writei");
  if(ip->type == T_DIR){
    dp->nlink--;  // 更新父目录的链接计数
    iupdate(dp);
  }
  iunlockput(dp);

  ip->nlink--;  // 更新目标文件的链接计数
  iupdate(ip);
  iunlockput(ip);

  end_op();

  return 0;

bad:
  iunlockput(dp);
  end_op();
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)  // 查找父目录
    return 0;

  ilock(dp);

  if((ip = dirlookup(dp, name, 0)) != 0){  // 检查文件是否已存在
    iunlockput(dp);
    ilock(ip);
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
      return ip;
    iunlockput(ip);
    return 0;
  }

  if((ip = ialloc(dp->dev, type)) == 0){  // 分配 inode
    iunlockput(dp);
    return 0;
  }

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  if(type == T_DIR){  // 创建 . 和 .. 目录项
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      goto fail;
  }

  if(dirlink(dp, name, ip->inum) < 0)
    goto fail;

  if(type == T_DIR){
    dp->nlink++;  // 更新父目录的链接计数
    iupdate(dp);
  }

  iunlockput(dp);

  return ip;

 fail:
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}

uint64
sys_open(void)
{
  char path[MAXPATH];
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);  // 获取打开文件的模式
  if((n = argstr(0, path, MAXPATH)) < 0)  // 获取路径
    return -1;

  begin_op();

  if(omode & O_CREATE){  // 如果是创建文件
    ip = create(path, T_FILE, 0, 0);
    if(ip == 0){
      end_op();
      return -1;
    }
  } else {  // 如果是打开已有文件
    if((ip = namei(path)) == 0){
      end_op();
      return -1;
    }
    ilock(ip);
    if(ip->type == T_DIR && omode != O_RDONLY){  // 不能用非读模式打开目录
      iunlockput(ip);
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){  // 分配文件描述符
    if(f)
      fileclose(f);
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    f->off = 0;
  }
  f->ip = ip;
  f->readable = !(omode & O_WRONLY);
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

  if((omode & O_TRUNC) && ip->type == T_FILE){  // 如果是 O_TRUNC 模式，截断文件
    itrunc(ip);
  }

  iunlock(ip);
  end_op();

  return fd;
}

uint64
sys_mkdir(void)
{
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_mknod(void)
{
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
  argint(1, &major);
  argint(2, &minor);
  if((argstr(0, path, MAXPATH)) < 0 ||
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    end_op();
    return -1;
  }
  iunlockput(ip);
  end_op();
  return 0;
}

uint64
sys_chdir(void)
{
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
  
  begin_op();
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    end_op();
    return -1;
  }
  ilock(ip);
  if(ip->type != T_DIR){  // 必须是目录类型
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
  iput(p->cwd);  // 释放当前工作目录
  end_op();
  p->cwd = ip;  // 更新为新的工作目录
  return 0;
}

uint64
sys_exec(void)
{
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);  // 获取参数地址
  if(argstr(0, path, MAXPATH) < 0) {  // 获取程序路径
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
    if(i >= NELEM(argv)){
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
      goto bad;
    }
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    if(argv[i] == 0)
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
      goto bad;
  }

  int ret = kexec(path, argv);  // 执行程序

  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    kfree(argv[i]);
  return -1;
}

uint64
sys_pipe(void)
{
  uint64 fdarray; // 用户指针指向两个整数的数组
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();

  argaddr(0, &fdarray);  // 获取文件描述符数组地址
  if(pipealloc(&rf, &wf) < 0)  // 分配管道文件
    return -1;
  fd0 = -1;
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){  // 分配文件描述符
    if(fd0 >= 0)
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||  // 将文件描述符写入用户空间
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    p->ofile[fd0] = 0;
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
}

