// Simple command-line kernel monitor useful for
// controlling the kernel and exploring the system interactively.

#include <inc/stdio.h>
#include <inc/string.h>
#include <inc/memlayout.h>
#include <inc/assert.h>
#include <inc/x86.h>

#include <kern/console.h>
#include <kern/monitor.h>
#include <kern/kdebug.h>
#include <kern/trap.h>
#include <kern/pmap.h>

#define CMDBUF_SIZE	80	// enough for one VGA text line


struct Command {
	const char *name;
	const char *desc;
	// return -1 to force monitor to exit
	int (*func)(int argc, char** argv, struct Trapframe* tf);
};

static struct Command commands[] = {
	{ "help", "Display this list of commands", mon_help },
	{ "kerninfo", "Display information about the kernel", mon_kerninfo },
	{ "backtrace", "Display a listing of function call frames", mon_backtrace },
	{ "showmappings", "Show the mapping between physical address and virtualaddress", mon_showmappings},
	{ "perm", "Set/Change/Clear the permission of the page", mon_setperm},
	{ "c", "Continue execution the environment in current tf", moniter_ci},
	{ "continue", "Continue execution the environment in current tf", moniter_ci},
	{ "si", "Continue execution the next instruction in current tf", moniter_si},
	{ "stepi", "Continue execution the next instructionin current tf", moniter_si},
};

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	cprintf("Stack backtrace\n");

	uint32_t ebp_val = read_ebp();
	struct Eipdebuginfo eip_info;
	while (true){
		uintptr_t pointer = (uintptr_t) ebp_val;
		uint32_t new_ebp_val = *((uint32_t*)pointer);

		uint32_t ret_pos = *((uint32_t*)pointer + 1);
		uint32_t arg_1 = *((uint32_t*)pointer + 1 + 1);
		uint32_t arg_2 = *((uint32_t*)pointer + 1 + 2);
		uint32_t arg_3 = *((uint32_t*)pointer + 1 + 3);
		uint32_t arg_4 = *((uint32_t*)pointer + 1 + 4);
		uint32_t arg_5 = *((uint32_t*)pointer + 1 + 5);
		//
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
				ebp_val, ret_pos, arg_1, arg_2, arg_3, arg_4, arg_5);

		if (debuginfo_eip(ret_pos , &eip_info) == 0)
			cprintf("         %s:%d: %.*s+%d\r\n",
				eip_info.eip_file, eip_info.eip_line, 
				eip_info.eip_fn_namelen, eip_info.eip_fn_name,
				ret_pos - eip_info.eip_fn_addr);
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
			break;
		ebp_val = new_ebp_val;
	}
	return 0;
}

int mon_showmappings(int argc, char** argv, struct Trapframe *tf){
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;
	if (argc != 2 && argc != 3){
		cprintf("Usage: showmappings ADDR1 [ADDR2]\n");
		return 0;
	}

	long begin_itr = strtol(argv[1], NULL, 16);
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
	if (begin_itr > end_itr){
		long temp = begin_itr;
		begin_itr = end_itr;
		end_itr = temp;
	}

	if (end_itr > 0xffffffff)
		end_itr = 0xffffffff;
	begin_itr = ROUNDUP(begin_itr, PGSIZE);
	end_itr = ROUNDUP(end_itr, PGSIZE);

	
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
		if (pte_itr == NULL)
			cprintf("Page doesn't exist\n");
		else{
			cprintf("ADDR = %08x, ", PTE_ADDR(*pte_itr));
			cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
			cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
		}
	}

	return 0;
}

int mon_setperm(int argc, char** argv, struct Trapframe *tf){
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 4){
		cprintf("usage: perm ADDR [add/clear] [U/W/P] or perm ADDR [set] perm_code");
		return 0;
	}
	long addr = strtol(argv[1], NULL, 16);
	pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*) addr, false);
	if (pte_itr == NULL){
		cprintf("Page Doesn't Exist!");
		return 0;
	}
	cprintf("Before:");
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));

	if (strcmp("set", argv[2]) == 0){
		int perm_code = strtol(argv[3], NULL, 2);
		*pte_itr = *pte_itr ^ (perm_code & 7) ^ (*pte_itr & 7);
	}
	if (strcmp("add", argv[2]) == 0){
		int perm_code = 0;
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
		*pte_itr = *pte_itr | perm_code;
	}
	if (strcmp("clear", argv[2]) == 0){
		int perm_code = 0;
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
		*pte_itr = *pte_itr & (~perm_code);
	}

	cprintf("After:");
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));

	return 0;
}

int moniter_ci(int argc, char** argv, struct Trapframe *tf){
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
		cprintf("usage: c\n continue\n");
		return 0;
	}
	if (tf == NULL){
		cprintf("Not in backtrace mode\n");
		return 0;
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags &= ~0x100;
	env_run(curenv);
	return 0;
}
int moniter_si(int argc, char** argv, struct Trapframe *tf){
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
		cprintf("usage: si\n stepi\n");
		return 0;
	}
	if (tf == NULL){
		cprintf("Not in backtrace mode\n");
		return 0;
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags |= 0x100;
	env_run(curenv);
	return 0;
}

/***** Kernel monitor command interpreter *****/

#define WHITESPACE "\t\r\n "
#define MAXARGS 16

static int
runcmd(char *buf, struct Trapframe *tf)
{
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
		if (*buf == 0)
			break;

		// save and scan past next arg
		if (argc == MAXARGS - 1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
	}
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
	return 0;
}

void
monitor(struct Trapframe *tf)
{
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");

	if (tf != NULL)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
