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

PUBLIC struct time * get_rtc_time(){
	MESSAGE msg;
	msg.type=GET_RTC_TIME;
	send_recv(BOTH, TASK_SYS, &msg);
	assert(msg.type == SYSCALL_RET);

	return msg.BUF;
}