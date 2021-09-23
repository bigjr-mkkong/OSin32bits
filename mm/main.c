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

PRIVATE void init_mm();

PUBLIC void task_mm(){
	init_mm();

	while(1){
		send_recv(RECEIVE,ANY,&mm_msg);

		int src=mm_msg.source;
		int reply=1;

		int msgtype=mm_msg.type;

		switch(msgtype){
			case FORK:
				mm_msg.RETVAL=do_fork();
				break;
			default:
				dump_msg("Unkown Message: ",&mm_msg);
				assert(0);
				break;
		}
			
		if(reply){
			mm_msg.type=SYSCALL_RET;
			send_recv(SEND,src,&mm_msg);
		}
	}
}

PRIVATE void init_mm(){
	struct boot_params bp;
	get_boot_params(&bp);

	memory_size=bp.mem_size;
	printl("memsize: %dMB\n",memory_size/(1024*1024));
}

PUBLIC int alloc_mem(int pid,int memsize){
	assert(pid>=NR_TASKS+NR_NATIVE_PROCS);
	if(memsize>PROC_IMAGE_SIZE_DEFAULT){
		panic("alloc_mem failed to allocate memory: %d, too big\n",memsize);
	}

	int base=PROCS_BASE+(pid-(NR_TASKS+NR_NATIVE_PROCS))*PROC_IMAGE_SIZE_DEFAULT;
	if(base+memsize>=memory_size){
		panic("memory allocate failed, pid: %d\n",pid);
	}
	return base;
}