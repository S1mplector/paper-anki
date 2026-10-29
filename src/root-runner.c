#define _GNU_SOURCE
#include <sched.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/wait.h>
#include <sys/prctl.h>
#include <signal.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <limits.h>

static void die(const char *s) { perror(s); exit(1); }
int main(int argc,char **argv) {
    if(argc<3 || geteuid()!=0) { fprintf(stderr,"Usage (as root): root-runner ROOT COMMAND [ARGS...]\n"); return 2; }
    char root[PATH_MAX]; if(!realpath(argv[1],root))die("root path");
    if(unshare(CLONE_NEWNS|CLONE_NEWPID)<0)die("unshare");
    if(mount(NULL,"/",NULL,MS_REC|MS_PRIVATE,NULL)<0)die("private mounts");
    pid_t child=fork();if(child<0)die("fork");
    if(child) { int status;while(waitpid(child,&status,0)<0){if(errno!=EINTR)die("waitpid");}return WIFEXITED(status)?WEXITSTATUS(status):128+WTERMSIG(status); }
    if(prctl(PR_SET_PDEATHSIG,SIGKILL)<0)die("parent-death signal");
    if(mount(root,root,NULL,MS_BIND|MS_REC,NULL)<0)die("bind root");
    if(chdir(root)<0)die("chdir root");
    if(mkdir(".oldroot",0700)<0 && errno!=EEXIST)die("old root directory");
    if(syscall(SYS_pivot_root,".",".oldroot")<0)die("pivot_root");
    if(chdir("/")<0)die("chdir");
    if(umount2("/.oldroot",MNT_DETACH)<0)die("detach old root");
    umount2("/proc",MNT_DETACH);
    if(mount("proc","/proc","proc",MS_NOSUID|MS_NODEV|MS_NOEXEC,NULL)<0)die("mount proc");
    if(mount("sysfs","/sys","sysfs",MS_RDONLY|MS_NOSUID|MS_NODEV|MS_NOEXEC,NULL)<0)die("mount sysfs");
    execv(argv[2],argv+2);die("exec");
}
