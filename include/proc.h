struct stackframe {//low
	u32	gs;
	u32	fs;
	u32	es;
	u32	ds;
	u32	edi;
	u32	esi;
	u32	ebp;
	u32	kernel_esp;
	u32	ebx;		
	u32	edx;
	u32	ecx;
	u32	eax;
	u32	retaddr;
	u32	eip;
	u32	cs;
	u32	eflags;
	u32	esp;
	u32	ss;//high
};


struct proc {
	struct stackframe regs;

	u16 ldt_sel;
	struct descriptor ldts[LDT_SIZE];

        int ticks;
        int priority;

	char name[16];

	int  p_flags;//A proc is runnable iff p_flags==0

	MESSAGE * p_msg;
	int p_recvfrom;
	int p_sendto;

	int has_int_msg;           
	/*
	nonzero if an INTERRUPT occurred when
	the task is not ready to deal with it.
	*/

	struct proc * q_sending;   
	//queue of procs sending messages to this proc
	
	struct proc * next_sending;
	//next proc in the sending *queue (q_sending)

	int p_parent;

	int exit_status;

	struct file_desc * filp[NR_FILES];
};

struct task {
	task_f	initial_eip;
	int	stacksize;
	char	name[32];
};

#define proc2pid(x) (x - proc_table)


#define NR_TASKS		5
#define NR_PROCS		32
#define NR_NATIVE_PROCS		3
#define FIRST_PROC		proc_table[0]
#define LAST_PROC		proc_table[NR_TASKS + NR_PROCS - 1]
//forked process start here
#define	PROCS_BASE		0xA00000
#define	PROC_IMAGE_SIZE_DEFAULT	0x100000
#define	PROC_ORIGIN_STACK	0x400

//task stack def
#define	STACK_SIZE_DEFAULT	0x4000
#define STACK_SIZE_TTY		STACK_SIZE_DEFAULT
#define STACK_SIZE_SYS		STACK_SIZE_DEFAULT
#define STACK_SIZE_HD		STACK_SIZE_DEFAULT
#define STACK_SIZE_FS		STACK_SIZE_DEFAULT
#define STACK_SIZE_MM		STACK_SIZE_DEFAULT
#define STACK_SIZE_INIT		STACK_SIZE_DEFAULT
#define STACK_SIZE_TESTA	STACK_SIZE_DEFAULT
#define STACK_SIZE_TESTB	STACK_SIZE_DEFAULT

#define STACK_SIZE_TOTAL	(STACK_SIZE_TTY + \
				STACK_SIZE_SYS + \
				STACK_SIZE_HD + \
				STACK_SIZE_FS + \
				STACK_SIZE_MM + \
				STACK_SIZE_INIT + \
				STACK_SIZE_TESTA + \
				STACK_SIZE_TESTB)

