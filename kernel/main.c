#include "type.h"
#include "stdio.h"
#include "const.h"
#include "protect.h"
#include "string.h"
#include "fs.h"
#include "proc.h"
#include "tty.h"
#include "console.h"
#include "global.h"
#include "proto.h"

PUBLIC int kernel_main()
{
	disp_str("Initializing Process Table..........\n");

	int i,j,eflags,prio;
	u8 rpl;
	u8 priv;

	struct task *t;
	struct proc *p=proc_table;

	char *stk=task_stack+STACK_SIZE_TOTAL;

	for(i=0;i<NR_TASKS+NR_PROCS;i++,p++,t++){
		if(i>=NR_TASKS+NR_NATIVE_PROCS){
			p->p_flags=FREE_SLOT;
			continue;
		}

		if(i<NR_TASKS){
			t=task_table+i;
			priv=PRIVILEGE_TASK;
			rpl=RPL_TASK;
			eflags=0x1202;
			prio=100;
		}else{
			t=user_proc_table+(i-NR_TASKS);
			priv=PRIVILEGE_USER;
			rpl=RPL_USER;
			eflags=0x202;
			prio=50;
		}

		strcpy(p->name,t->name);
		p->p_parent=NO_TASK;

		if(strcmp(t->name,"INIT")!=0){
			p->ldts[INDEX_LDT_C]=gdt[SELECTOR_KERNEL_CS>>3];
			p->ldts[INDEX_LDT_RW]=gdt[SELECTOR_KERNEL_DS>>3];

			p->ldts[INDEX_LDT_C].attr1=DA_C|priv<<5;
			p->ldts[INDEX_LDT_RW].attr1=DA_DRW|priv<<5;
		}else{
			unsigned int k_base,k_limit;
			int ret=get_kernel_map(&k_base,&k_limit);
			assert(ret==0);
			init_desc(&p->ldts[INDEX_LDT_C],
				0,
				(k_base+k_limit)>>LIMIT_4K_SHIFT,
				DA_32|DA_LIMIT_4K|DA_C|priv<<5);
			init_desc(&p->ldts[INDEX_LDT_RW],
				0,
				(k_base+k_limit)>>LIMIT_4K_SHIFT,
				DA_32|DA_LIMIT_4K|DA_DRW|priv<<5);
		}

		p->regs.cs=INDEX_LDT_C<<3|SA_TIL|rpl;
		p->regs.ds=p->regs.es=p->regs.fs=p->regs.ss
		=INDEX_LDT_RW<<3|SA_TIL|rpl;
		p->regs.gs=(SELECTOR_KERNEL_GS&SA_RPL_MASK)|rpl;
		p->regs.eip=(u32)t->initial_eip;
		p->regs.esp=(u32)stk;
		p->regs.eflags=eflags;

		p->ticks=p->priority=prio;

		p->p_flags=0;
		p->p_msg=0;
		p->p_recvfrom=NO_TASK;
		p->p_sendto=NO_TASK;
		p->has_int_msg=0;
		p->q_sending=0;
		p->next_sending=0;

		for(j=0;j<NR_FILES;j++){
			p->filp[j]=0;
		}
		stk-=t->stacksize;
	}

	k_reenter = 0;
	ticks = 0;

	p_proc_ready = proc_table;

	init_clock();
    init_keyboard();

	restart();

	while(1){}
}

void TestA(){
	int fd_in=open("/dev_tty0",O_RDWR);
	int fd_out=open("/dev_tty0",O_RDWR);
	char rdbuf[128];
	printf("------------------------Terminal------------------------\n");
	while(1){
		printf("Command: ");
		read(fd_in,rdbuf,128);
		if(strcmp(rdbuf,"ps")==0){
			ps_com();
		}else if(strcmp(rdbuf,"ls")==0){
			ls_com();
		}else if(strcmp(rdbuf,"touch")==0){
			touch_com();
		}else if(strcmp(rdbuf,"edit")==0){
			edit_com();
		}else if(strcmp(rdbuf,"cat")==0){
			cat_com();
		}else if(strcmp(rdbuf,"rm")==0){
			rm_com();
		}else if(strcmp(rdbuf,"reboot")==0){
			//printl("rebooting...\n");
			reboot_com();
		}else if(strcmp(rdbuf,"shutdown")==0){
			shutdown_com(); 
			//printf("Can't you press the power buttom?\n");
		}else if(strcmp(rdbuf,"help")==0){
			printf("ls: list the file name of FILEs\n");
			printf("ps: list the process information\n");
			printf("touch: create a new file\n");
			printf("edit: edit the text of exists file\n");
			printf("cat: catch the context of certain file\n");
			printf("rm: remove certain file\n");
			printf("time: get real time\n");
			printf("reboot: reboot the computer\n");
			printf("shutdown: shutdown the computer(only avaliablein Bochs and QEMU)\n");
		}else if(strcmp(rdbuf,"")==0){
			continue;
		}else if(strcmp(rdbuf,"time")==0){
			get_real_time();
		}else{
			printf(" \"%s\" is not a valid command\n",rdbuf);
		}
		memset(rdbuf,0,128);
	}
}

void TestB(){
	int stdin=open("/dev_tty1",O_RDWR);
	int stdout=open("/dev_tty1",O_RDWR);

	while(1){
		read(stdin,tty_communi,TTY_COMMUNI_SIZE);
	}
}

PUBLIC void panic(const char *fmt, ...){
	int i;
	char buf[256];

	va_list arg = (va_list)((char*)&fmt + 4);
	i = vsprintf(buf, fmt, arg);
	printl("%c !!panic!! %s", MAG_CH_PANIC, buf);

	__asm__ __volatile__("ud2");
}

PUBLIC int get_ticks(){
	MESSAGE msg;
	reset_msg(&msg);
	msg.type = GET_TICKS;
	send_recv(BOTH, TASK_SYS, &msg);
	return msg.RETVAL;
}

void Init(){
	for(;;){}
}