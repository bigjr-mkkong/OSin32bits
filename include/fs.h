#ifndef	_ORANGES_FS_H_
#define	_ORANGES_FS_H_


struct dev_drv_map {
	int driver_nr; //The proc nr.\ of the device driver.
};


#define	MAGIC_V1	0x111//magic num of FS


struct super_block {
	u32	magic;//magic number
	u32	nr_inodes;//inodes num
	u32	nr_sects;//sector num
	u32	nr_imap_sects;//inodes map occupation(sectors)
	u32	nr_smap_sects;//sector map occupation(sectors)
	u32	n_1st_sect;//Number of the 1st data sector
	u32	nr_inode_sects;//inode occupation(secotrs)
	u32	root_inode;//root directory inode num
	u32	inode_size;//INODE_SIZE
	u32	inode_isize_off;//Offset of struct inode::i_size
	u32	inode_start_off;//Offset of struct inode::i_start_sect
	u32	dir_ent_size;//DIR_ENTRY_SIZE
	u32	dir_ent_inode_off;//Offset of struct dir_entry::inode_nr
	u32	dir_ent_fname_off;//Offset of struct dir_entry::name

	int	sb_dev;//the super block's home device
};

#define	SUPER_BLOCK_SIZE	56 //ignore sb_dev

struct inode {
	u32	i_mode;// access mode
	u32	i_size;//file size
	u32	i_start_sect;//first sector number of data
	u32	i_nr_sects;//sector number file occupied
	u8	_unused[16];//for alignment

	int	i_dev;
	int	i_cnt;//number of process sharing this file
	int	i_num;//inode id
};

#define	INODE_SIZE	32


#define	MAX_FILENAME_LEN	12

struct dir_entry {
	int	inode_nr;//inode number
	char name[MAX_FILENAME_LEN];//filename
};

#define	DIR_ENTRY_SIZE	sizeof(struct dir_entry)

struct file_desc {
	int	fd_mode;//R||W
	int	fd_pos;//current position for R||W
	int	fd_cnt;//number of process sharing this desc
	struct inode* fd_inode;// ptr to inode
};

#define RD_SECT(dev,sect_nr) rw_sector(DEV_READ,\
				       dev,\
				       (sect_nr) * SECTOR_SIZE,\
				       SECTOR_SIZE,\
				       TASK_FS,\
				       fsbuf);
#define WR_SECT(dev,sect_nr) rw_sector(DEV_WRITE,\
				       dev,\
				       (sect_nr) * SECTOR_SIZE,\
				       SECTOR_SIZE,\
				       TASK_FS,\
				       fsbuf);
#endif
