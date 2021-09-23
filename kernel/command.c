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

PUBLIC void ps_com(){
	printl("PID      Name      Priority      Ticks\n");
	for(int i=0;i<NR_TASKS+NR_PROCS;i++){
		if(proc_table[i].p_flags!=32){
			printl("%d        %s     %d           %d\n",
				i,proc_table[i].name,
				proc_table[i].priority,proc_table[i].ticks);
		}
	}
}

PUBLIC void ls_com(){
	struct inode *dir_inode;
	strip_path("dev_tty0","/dev_tty0",&dir_inode);

	int dir_blk0_nr=dir_inode->i_start_sect;
	int nr_dir_blks=(dir_inode->i_size+SECTOR_SIZE-1)/SECTOR_SIZE;
	int nr_dir_entries=dir_inode->i_size/DIR_ENTRY_SIZE;

	int m=0;
	struct dir_entry * pde;
	for(int i=0;i<nr_dir_blks;i++){
		RD_SECT(dir_inode->i_dev,dir_blk0_nr+i);
		pde=(struct dir_entry*)fsbuf;
		for(int j=0;j<SECTOR_SIZE/DIR_ENTRY_SIZE;j++,pde++){
			printl("________________________________\n");
			printl("FileName: %s\n",pde->name);
			printl("INode Number: %d\n",pde->inode_nr);
			if(++m>nr_dir_entries) break;
		}
		if(m>nr_dir_entries) break;
	}
}

PUBLIC void touch_com(){
	char filename[16];
	memset(filename,0,16);
	printl("please enter file name: \n");
	int fd_in=open("/dev_tty0",O_RDWR);
	read(fd_in,filename,16);
	int file_desc=open(filename,O_CREAT);
	close(fd_in);
	close(file_desc);
	return;
}

PUBLIC void edit_com(){
	memset(tty_communi,0,TTY_COMMUNI_SIZE);
	char filename[16];
	char buf[5];
	memset(filename,0,16);
	memset(buf,0,5);
	int file_in;

	printl("please enter file name: \n");
	int fd_stdin=open("/dev_tty0",O_RDWR);
	read(fd_stdin,filename,16);

	printl("please enter text in Terminal #2\n");
	printl("finish(y)/quit(*): ");
	read(fd_stdin,buf,2);
	if(strcmp(buf,"y")==0||strcmp(buf,"Y")==0){
		file_in=open(filename,O_RDWR);
		//printl("data going to write: %s\n",tty_communi);
		write(file_in,tty_communi,TTY_COMMUNI_SIZE);
	}else{
		printl("file writing stopped\n");
		close(fd_stdin);
		return;
	}
	close(fd_stdin);
	close(file_in);
	return;
}

PUBLIC void cat_com(){
	memset(tty_communi,0,TTY_COMMUNI_SIZE);
	char filename[16],buf[TTY_COMMUNI_SIZE];
	memset(filename,0,16);
	memset(buf,0,TTY_COMMUNI_SIZE);
	int file_in;

	printl("please enter file name: \n");
	int fd_stdin=open("/dev_tty0",O_RDWR);
	read(fd_stdin,filename,16);

	file_in=open(filename,O_RDWR);
	read(file_in,buf,16);

	printl("\n%s\n",buf);

	close(fd_stdin);
	close(file_in);
	return;
}

PUBLIC void rm_com(){
	memset(tty_communi,0,TTY_COMMUNI_SIZE);
	char filename[16];
	memset(filename,0,16);

	printl("please enter file name: \n");
	int fd_stdin=open("/dev_tty0",O_RDWR);
	read(fd_stdin,filename,16);

	unlink(filename);

	close(fd_stdin);
	return;
}

PUBLIC void get_real_time(){
	struct time *t=get_rtc_time();
	printl("%d/%d/%d   %d\n",
		t->year,
		t->month,
		t->day,
		t->week
		);
	return;
}