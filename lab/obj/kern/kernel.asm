
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 10 12 f0       	mov    $0xf0121000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5e 00 00 00       	call   f010009c <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100048:	83 3d 80 6e 21 f0 00 	cmpl   $0x0,0xf0216e80
f010004f:	74 0f                	je     f0100060 <_panic+0x20>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100051:	83 ec 0c             	sub    $0xc,%esp
f0100054:	6a 00                	push   $0x0
f0100056:	e8 31 0d 00 00       	call   f0100d8c <monitor>
f010005b:	83 c4 10             	add    $0x10,%esp
f010005e:	eb f1                	jmp    f0100051 <_panic+0x11>
	panicstr = fmt;
f0100060:	89 35 80 6e 21 f0    	mov    %esi,0xf0216e80
	asm volatile("cli; cld");
f0100066:	fa                   	cli    
f0100067:	fc                   	cld    
	va_start(ap, fmt);
f0100068:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010006b:	e8 33 64 00 00       	call   f01064a3 <cpunum>
f0100070:	ff 75 0c             	pushl  0xc(%ebp)
f0100073:	ff 75 08             	pushl  0x8(%ebp)
f0100076:	50                   	push   %eax
f0100077:	68 e0 6a 10 f0       	push   $0xf0106ae0
f010007c:	e8 ea 3c 00 00       	call   f0103d6b <cprintf>
	vcprintf(fmt, ap);
f0100081:	83 c4 08             	add    $0x8,%esp
f0100084:	53                   	push   %ebx
f0100085:	56                   	push   %esi
f0100086:	e8 ba 3c 00 00       	call   f0103d45 <vcprintf>
	cprintf("\n");
f010008b:	c7 04 24 4b 6e 10 f0 	movl   $0xf0106e4b,(%esp)
f0100092:	e8 d4 3c 00 00       	call   f0103d6b <cprintf>
f0100097:	83 c4 10             	add    $0x10,%esp
f010009a:	eb b5                	jmp    f0100051 <_panic+0x11>

f010009c <i386_init>:
{
f010009c:	55                   	push   %ebp
f010009d:	89 e5                	mov    %esp,%ebp
f010009f:	53                   	push   %ebx
f01000a0:	83 ec 04             	sub    $0x4,%esp
	cons_init();
f01000a3:	e8 ae 05 00 00       	call   f0100656 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000a8:	83 ec 08             	sub    $0x8,%esp
f01000ab:	68 ac 1a 00 00       	push   $0x1aac
f01000b0:	68 4c 6b 10 f0       	push   $0xf0106b4c
f01000b5:	e8 b1 3c 00 00       	call   f0103d6b <cprintf>
	mem_init();
f01000ba:	e8 f3 16 00 00       	call   f01017b2 <mem_init>
	env_init();
f01000bf:	e8 1a 35 00 00       	call   f01035de <env_init>
	trap_init();
f01000c4:	e8 5b 3d 00 00       	call   f0103e24 <trap_init>
	mp_init();
f01000c9:	e8 c3 60 00 00       	call   f0106191 <mp_init>
	lapic_init();
f01000ce:	e8 ea 63 00 00       	call   f01064bd <lapic_init>
	pic_init();
f01000d3:	e8 b6 3b 00 00       	call   f0103c8e <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000d8:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f01000df:	e8 2f 66 00 00       	call   f0106713 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000e4:	83 c4 10             	add    $0x10,%esp
f01000e7:	83 3d 88 6e 21 f0 07 	cmpl   $0x7,0xf0216e88
f01000ee:	76 27                	jbe    f0100117 <i386_init+0x7b>
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f01000f0:	83 ec 04             	sub    $0x4,%esp
f01000f3:	b8 f6 60 10 f0       	mov    $0xf01060f6,%eax
f01000f8:	2d 7c 60 10 f0       	sub    $0xf010607c,%eax
f01000fd:	50                   	push   %eax
f01000fe:	68 7c 60 10 f0       	push   $0xf010607c
f0100103:	68 00 70 00 f0       	push   $0xf0007000
f0100108:	e8 bd 5d 00 00       	call   f0105eca <memmove>
f010010d:	83 c4 10             	add    $0x10,%esp
	for (c = cpus; c < cpus + ncpu; c++) {
f0100110:	bb 20 70 21 f0       	mov    $0xf0217020,%ebx
f0100115:	eb 19                	jmp    f0100130 <i386_init+0x94>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100117:	68 00 70 00 00       	push   $0x7000
f010011c:	68 04 6b 10 f0       	push   $0xf0106b04
f0100121:	6a 54                	push   $0x54
f0100123:	68 67 6b 10 f0       	push   $0xf0106b67
f0100128:	e8 13 ff ff ff       	call   f0100040 <_panic>
f010012d:	83 c3 74             	add    $0x74,%ebx
f0100130:	6b 05 c4 73 21 f0 74 	imul   $0x74,0xf02173c4,%eax
f0100137:	05 20 70 21 f0       	add    $0xf0217020,%eax
f010013c:	39 c3                	cmp    %eax,%ebx
f010013e:	73 4c                	jae    f010018c <i386_init+0xf0>
		if (c == cpus + cpunum())  // We've started already.
f0100140:	e8 5e 63 00 00       	call   f01064a3 <cpunum>
f0100145:	6b c0 74             	imul   $0x74,%eax,%eax
f0100148:	05 20 70 21 f0       	add    $0xf0217020,%eax
f010014d:	39 c3                	cmp    %eax,%ebx
f010014f:	74 dc                	je     f010012d <i386_init+0x91>
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100151:	89 d8                	mov    %ebx,%eax
f0100153:	2d 20 70 21 f0       	sub    $0xf0217020,%eax
f0100158:	c1 f8 02             	sar    $0x2,%eax
f010015b:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100161:	c1 e0 0f             	shl    $0xf,%eax
f0100164:	05 00 00 22 f0       	add    $0xf0220000,%eax
f0100169:	a3 84 6e 21 f0       	mov    %eax,0xf0216e84
		lapic_startap(c->cpu_id, PADDR(code));
f010016e:	83 ec 08             	sub    $0x8,%esp
f0100171:	68 00 70 00 00       	push   $0x7000
f0100176:	0f b6 03             	movzbl (%ebx),%eax
f0100179:	50                   	push   %eax
f010017a:	e8 8f 64 00 00       	call   f010660e <lapic_startap>
f010017f:	83 c4 10             	add    $0x10,%esp
		while(c->cpu_status != CPU_STARTED)
f0100182:	8b 43 04             	mov    0x4(%ebx),%eax
f0100185:	83 f8 01             	cmp    $0x1,%eax
f0100188:	75 f8                	jne    f0100182 <i386_init+0xe6>
f010018a:	eb a1                	jmp    f010012d <i386_init+0x91>
	ENV_CREATE(fs_fs, ENV_TYPE_FS);
f010018c:	83 ec 08             	sub    $0x8,%esp
f010018f:	6a 01                	push   $0x1
f0100191:	68 a8 38 1d f0       	push   $0xf01d38a8
f0100196:	e8 e0 35 00 00       	call   f010377b <env_create>
	ENV_CREATE(user_spawnhello, ENV_TYPE_USER);
f010019b:	83 c4 08             	add    $0x8,%esp
f010019e:	6a 00                	push   $0x0
f01001a0:	68 f8 9b 1c f0       	push   $0xf01c9bf8
f01001a5:	e8 d1 35 00 00       	call   f010377b <env_create>
	kbd_intr();
f01001aa:	e8 4c 04 00 00       	call   f01005fb <kbd_intr>
	sched_yield();
f01001af:	e8 41 4a 00 00       	call   f0104bf5 <sched_yield>

f01001b4 <mp_main>:
{
f01001b4:	55                   	push   %ebp
f01001b5:	89 e5                	mov    %esp,%ebp
f01001b7:	83 ec 08             	sub    $0x8,%esp
	lcr3(PADDR(kern_pgdir));
f01001ba:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01001bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c4:	77 12                	ja     f01001d8 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c6:	50                   	push   %eax
f01001c7:	68 28 6b 10 f0       	push   $0xf0106b28
f01001cc:	6a 6b                	push   $0x6b
f01001ce:	68 67 6b 10 f0       	push   $0xf0106b67
f01001d3:	e8 68 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001d8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01001dd:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001e0:	e8 be 62 00 00       	call   f01064a3 <cpunum>
f01001e5:	83 ec 08             	sub    $0x8,%esp
f01001e8:	50                   	push   %eax
f01001e9:	68 73 6b 10 f0       	push   $0xf0106b73
f01001ee:	e8 78 3b 00 00       	call   f0103d6b <cprintf>
	lapic_init();
f01001f3:	e8 c5 62 00 00       	call   f01064bd <lapic_init>
	env_init_percpu();
f01001f8:	e8 b1 33 00 00       	call   f01035ae <env_init_percpu>
	trap_init_percpu();
f01001fd:	e8 7d 3b 00 00       	call   f0103d7f <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100202:	e8 9c 62 00 00       	call   f01064a3 <cpunum>
f0100207:	6b d0 74             	imul   $0x74,%eax,%edx
f010020a:	83 c2 04             	add    $0x4,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1"
f010020d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100212:	f0 87 82 20 70 21 f0 	lock xchg %eax,-0xfde8fe0(%edx)
f0100219:	c7 04 24 c0 33 12 f0 	movl   $0xf01233c0,(%esp)
f0100220:	e8 ee 64 00 00       	call   f0106713 <spin_lock>
	sched_yield();
f0100225:	e8 cb 49 00 00       	call   f0104bf5 <sched_yield>

f010022a <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010022a:	55                   	push   %ebp
f010022b:	89 e5                	mov    %esp,%ebp
f010022d:	53                   	push   %ebx
f010022e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100231:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100234:	ff 75 0c             	pushl  0xc(%ebp)
f0100237:	ff 75 08             	pushl  0x8(%ebp)
f010023a:	68 89 6b 10 f0       	push   $0xf0106b89
f010023f:	e8 27 3b 00 00       	call   f0103d6b <cprintf>
	vcprintf(fmt, ap);
f0100244:	83 c4 08             	add    $0x8,%esp
f0100247:	53                   	push   %ebx
f0100248:	ff 75 10             	pushl  0x10(%ebp)
f010024b:	e8 f5 3a 00 00       	call   f0103d45 <vcprintf>
	cprintf("\n");
f0100250:	c7 04 24 4b 6e 10 f0 	movl   $0xf0106e4b,(%esp)
f0100257:	e8 0f 3b 00 00       	call   f0103d6b <cprintf>
	va_end(ap);
}
f010025c:	83 c4 10             	add    $0x10,%esp
f010025f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100262:	c9                   	leave  
f0100263:	c3                   	ret    

f0100264 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100264:	55                   	push   %ebp
f0100265:	89 e5                	mov    %esp,%ebp
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100267:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010026c:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010026d:	a8 01                	test   $0x1,%al
f010026f:	74 0b                	je     f010027c <serial_proc_data+0x18>
f0100271:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100276:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100277:	0f b6 c0             	movzbl %al,%eax
}
f010027a:	5d                   	pop    %ebp
f010027b:	c3                   	ret    
		return -1;
f010027c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100281:	eb f7                	jmp    f010027a <serial_proc_data+0x16>

f0100283 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100283:	55                   	push   %ebp
f0100284:	89 e5                	mov    %esp,%ebp
f0100286:	53                   	push   %ebx
f0100287:	83 ec 04             	sub    $0x4,%esp
f010028a:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028c:	ff d3                	call   *%ebx
f010028e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100291:	74 2d                	je     f01002c0 <cons_intr+0x3d>
		if (c == 0)
f0100293:	85 c0                	test   %eax,%eax
f0100295:	74 f5                	je     f010028c <cons_intr+0x9>
			continue;
		cons.buf[cons.wpos++] = c;
f0100297:	8b 0d 24 62 21 f0    	mov    0xf0216224,%ecx
f010029d:	8d 51 01             	lea    0x1(%ecx),%edx
f01002a0:	89 15 24 62 21 f0    	mov    %edx,0xf0216224
f01002a6:	88 81 20 60 21 f0    	mov    %al,-0xfde9fe0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01002ac:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01002b2:	75 d8                	jne    f010028c <cons_intr+0x9>
			cons.wpos = 0;
f01002b4:	c7 05 24 62 21 f0 00 	movl   $0x0,0xf0216224
f01002bb:	00 00 00 
f01002be:	eb cc                	jmp    f010028c <cons_intr+0x9>
	}
}
f01002c0:	83 c4 04             	add    $0x4,%esp
f01002c3:	5b                   	pop    %ebx
f01002c4:	5d                   	pop    %ebp
f01002c5:	c3                   	ret    

f01002c6 <kbd_proc_data>:
{
f01002c6:	55                   	push   %ebp
f01002c7:	89 e5                	mov    %esp,%ebp
f01002c9:	53                   	push   %ebx
f01002ca:	83 ec 04             	sub    $0x4,%esp
f01002cd:	ba 64 00 00 00       	mov    $0x64,%edx
f01002d2:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01002d3:	a8 01                	test   $0x1,%al
f01002d5:	0f 84 fa 00 00 00    	je     f01003d5 <kbd_proc_data+0x10f>
	if (stat & KBS_TERR)
f01002db:	a8 20                	test   $0x20,%al
f01002dd:	0f 85 f9 00 00 00    	jne    f01003dc <kbd_proc_data+0x116>
f01002e3:	ba 60 00 00 00       	mov    $0x60,%edx
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01002eb:	3c e0                	cmp    $0xe0,%al
f01002ed:	0f 84 8e 00 00 00    	je     f0100381 <kbd_proc_data+0xbb>
	} else if (data & 0x80) {
f01002f3:	84 c0                	test   %al,%al
f01002f5:	0f 88 99 00 00 00    	js     f0100394 <kbd_proc_data+0xce>
	} else if (shift & E0ESC) {
f01002fb:	8b 0d 00 60 21 f0    	mov    0xf0216000,%ecx
f0100301:	f6 c1 40             	test   $0x40,%cl
f0100304:	74 0e                	je     f0100314 <kbd_proc_data+0x4e>
		data |= 0x80;
f0100306:	83 c8 80             	or     $0xffffff80,%eax
f0100309:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010030b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010030e:	89 0d 00 60 21 f0    	mov    %ecx,0xf0216000
	shift |= shiftcode[data];
f0100314:	0f b6 d2             	movzbl %dl,%edx
f0100317:	0f b6 82 00 6d 10 f0 	movzbl -0xfef9300(%edx),%eax
f010031e:	0b 05 00 60 21 f0    	or     0xf0216000,%eax
	shift ^= togglecode[data];
f0100324:	0f b6 8a 00 6c 10 f0 	movzbl -0xfef9400(%edx),%ecx
f010032b:	31 c8                	xor    %ecx,%eax
f010032d:	a3 00 60 21 f0       	mov    %eax,0xf0216000
	c = charcode[shift & (CTL | SHIFT)][data];
f0100332:	89 c1                	mov    %eax,%ecx
f0100334:	83 e1 03             	and    $0x3,%ecx
f0100337:	8b 0c 8d e0 6b 10 f0 	mov    -0xfef9420(,%ecx,4),%ecx
f010033e:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100342:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100345:	a8 08                	test   $0x8,%al
f0100347:	74 0d                	je     f0100356 <kbd_proc_data+0x90>
		if ('a' <= c && c <= 'z')
f0100349:	89 da                	mov    %ebx,%edx
f010034b:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f010034e:	83 f9 19             	cmp    $0x19,%ecx
f0100351:	77 74                	ja     f01003c7 <kbd_proc_data+0x101>
			c += 'A' - 'a';
f0100353:	83 eb 20             	sub    $0x20,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100356:	f7 d0                	not    %eax
f0100358:	a8 06                	test   $0x6,%al
f010035a:	75 31                	jne    f010038d <kbd_proc_data+0xc7>
f010035c:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100362:	75 29                	jne    f010038d <kbd_proc_data+0xc7>
		cprintf("Rebooting!\n");
f0100364:	83 ec 0c             	sub    $0xc,%esp
f0100367:	68 a3 6b 10 f0       	push   $0xf0106ba3
f010036c:	e8 fa 39 00 00       	call   f0103d6b <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100371:	b8 03 00 00 00       	mov    $0x3,%eax
f0100376:	ba 92 00 00 00       	mov    $0x92,%edx
f010037b:	ee                   	out    %al,(%dx)
f010037c:	83 c4 10             	add    $0x10,%esp
f010037f:	eb 0c                	jmp    f010038d <kbd_proc_data+0xc7>
		shift |= E0ESC;
f0100381:	83 0d 00 60 21 f0 40 	orl    $0x40,0xf0216000
		return 0;
f0100388:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f010038d:	89 d8                	mov    %ebx,%eax
f010038f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100392:	c9                   	leave  
f0100393:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100394:	8b 0d 00 60 21 f0    	mov    0xf0216000,%ecx
f010039a:	89 cb                	mov    %ecx,%ebx
f010039c:	83 e3 40             	and    $0x40,%ebx
f010039f:	83 e0 7f             	and    $0x7f,%eax
f01003a2:	85 db                	test   %ebx,%ebx
f01003a4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003a7:	0f b6 d2             	movzbl %dl,%edx
f01003aa:	0f b6 82 00 6d 10 f0 	movzbl -0xfef9300(%edx),%eax
f01003b1:	83 c8 40             	or     $0x40,%eax
f01003b4:	0f b6 c0             	movzbl %al,%eax
f01003b7:	f7 d0                	not    %eax
f01003b9:	21 c8                	and    %ecx,%eax
f01003bb:	a3 00 60 21 f0       	mov    %eax,0xf0216000
		return 0;
f01003c0:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003c5:	eb c6                	jmp    f010038d <kbd_proc_data+0xc7>
		else if ('A' <= c && c <= 'Z')
f01003c7:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003ca:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003cd:	83 fa 1a             	cmp    $0x1a,%edx
f01003d0:	0f 42 d9             	cmovb  %ecx,%ebx
f01003d3:	eb 81                	jmp    f0100356 <kbd_proc_data+0x90>
		return -1;
f01003d5:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003da:	eb b1                	jmp    f010038d <kbd_proc_data+0xc7>
		return -1;
f01003dc:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f01003e1:	eb aa                	jmp    f010038d <kbd_proc_data+0xc7>

f01003e3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003e3:	55                   	push   %ebp
f01003e4:	89 e5                	mov    %esp,%ebp
f01003e6:	57                   	push   %edi
f01003e7:	56                   	push   %esi
f01003e8:	53                   	push   %ebx
f01003e9:	83 ec 1c             	sub    $0x1c,%esp
f01003ec:	89 c7                	mov    %eax,%edi
	for (i = 0;
f01003ee:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003f8:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003fd:	eb 09                	jmp    f0100408 <cons_putc+0x25>
f01003ff:	89 ca                	mov    %ecx,%edx
f0100401:	ec                   	in     (%dx),%al
f0100402:	ec                   	in     (%dx),%al
f0100403:	ec                   	in     (%dx),%al
f0100404:	ec                   	in     (%dx),%al
	     i++)
f0100405:	83 c3 01             	add    $0x1,%ebx
f0100408:	89 f2                	mov    %esi,%edx
f010040a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010040b:	a8 20                	test   $0x20,%al
f010040d:	75 08                	jne    f0100417 <cons_putc+0x34>
f010040f:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100415:	7e e8                	jle    f01003ff <cons_putc+0x1c>
	outb(COM1 + COM_TX, c);
f0100417:	89 f8                	mov    %edi,%eax
f0100419:	88 45 e7             	mov    %al,-0x19(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010041c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100421:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100422:	bb 00 00 00 00       	mov    $0x0,%ebx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100427:	be 79 03 00 00       	mov    $0x379,%esi
f010042c:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100431:	eb 09                	jmp    f010043c <cons_putc+0x59>
f0100433:	89 ca                	mov    %ecx,%edx
f0100435:	ec                   	in     (%dx),%al
f0100436:	ec                   	in     (%dx),%al
f0100437:	ec                   	in     (%dx),%al
f0100438:	ec                   	in     (%dx),%al
f0100439:	83 c3 01             	add    $0x1,%ebx
f010043c:	89 f2                	mov    %esi,%edx
f010043e:	ec                   	in     (%dx),%al
f010043f:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100445:	7f 04                	jg     f010044b <cons_putc+0x68>
f0100447:	84 c0                	test   %al,%al
f0100449:	79 e8                	jns    f0100433 <cons_putc+0x50>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044b:	ba 78 03 00 00       	mov    $0x378,%edx
f0100450:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100454:	ee                   	out    %al,(%dx)
f0100455:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010045a:	b8 0d 00 00 00       	mov    $0xd,%eax
f010045f:	ee                   	out    %al,(%dx)
f0100460:	b8 08 00 00 00       	mov    $0x8,%eax
f0100465:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100466:	89 fa                	mov    %edi,%edx
f0100468:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010046e:	89 f8                	mov    %edi,%eax
f0100470:	80 cc 07             	or     $0x7,%ah
f0100473:	85 d2                	test   %edx,%edx
f0100475:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100478:	89 f8                	mov    %edi,%eax
f010047a:	0f b6 c0             	movzbl %al,%eax
f010047d:	83 f8 09             	cmp    $0x9,%eax
f0100480:	0f 84 b6 00 00 00    	je     f010053c <cons_putc+0x159>
f0100486:	83 f8 09             	cmp    $0x9,%eax
f0100489:	7e 73                	jle    f01004fe <cons_putc+0x11b>
f010048b:	83 f8 0a             	cmp    $0xa,%eax
f010048e:	0f 84 9b 00 00 00    	je     f010052f <cons_putc+0x14c>
f0100494:	83 f8 0d             	cmp    $0xd,%eax
f0100497:	0f 85 d6 00 00 00    	jne    f0100573 <cons_putc+0x190>
		crt_pos -= (crt_pos % CRT_COLS);
f010049d:	0f b7 05 28 62 21 f0 	movzwl 0xf0216228,%eax
f01004a4:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004aa:	c1 e8 16             	shr    $0x16,%eax
f01004ad:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004b0:	c1 e0 04             	shl    $0x4,%eax
f01004b3:	66 a3 28 62 21 f0    	mov    %ax,0xf0216228
	if (crt_pos >= CRT_SIZE) {
f01004b9:	66 81 3d 28 62 21 f0 	cmpw   $0x7cf,0xf0216228
f01004c0:	cf 07 
f01004c2:	0f 87 ce 00 00 00    	ja     f0100596 <cons_putc+0x1b3>
	outb(addr_6845, 14);
f01004c8:	8b 0d 30 62 21 f0    	mov    0xf0216230,%ecx
f01004ce:	b8 0e 00 00 00       	mov    $0xe,%eax
f01004d3:	89 ca                	mov    %ecx,%edx
f01004d5:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01004d6:	0f b7 1d 28 62 21 f0 	movzwl 0xf0216228,%ebx
f01004dd:	8d 71 01             	lea    0x1(%ecx),%esi
f01004e0:	89 d8                	mov    %ebx,%eax
f01004e2:	66 c1 e8 08          	shr    $0x8,%ax
f01004e6:	89 f2                	mov    %esi,%edx
f01004e8:	ee                   	out    %al,(%dx)
f01004e9:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ee:	89 ca                	mov    %ecx,%edx
f01004f0:	ee                   	out    %al,(%dx)
f01004f1:	89 d8                	mov    %ebx,%eax
f01004f3:	89 f2                	mov    %esi,%edx
f01004f5:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004f9:	5b                   	pop    %ebx
f01004fa:	5e                   	pop    %esi
f01004fb:	5f                   	pop    %edi
f01004fc:	5d                   	pop    %ebp
f01004fd:	c3                   	ret    
	switch (c & 0xff) {
f01004fe:	83 f8 08             	cmp    $0x8,%eax
f0100501:	75 70                	jne    f0100573 <cons_putc+0x190>
		if (crt_pos > 0) {
f0100503:	0f b7 05 28 62 21 f0 	movzwl 0xf0216228,%eax
f010050a:	66 85 c0             	test   %ax,%ax
f010050d:	74 b9                	je     f01004c8 <cons_putc+0xe5>
			crt_pos--;
f010050f:	83 e8 01             	sub    $0x1,%eax
f0100512:	66 a3 28 62 21 f0    	mov    %ax,0xf0216228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100518:	0f b7 c0             	movzwl %ax,%eax
f010051b:	66 81 e7 00 ff       	and    $0xff00,%di
f0100520:	83 cf 20             	or     $0x20,%edi
f0100523:	8b 15 2c 62 21 f0    	mov    0xf021622c,%edx
f0100529:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010052d:	eb 8a                	jmp    f01004b9 <cons_putc+0xd6>
		crt_pos += CRT_COLS;
f010052f:	66 83 05 28 62 21 f0 	addw   $0x50,0xf0216228
f0100536:	50 
f0100537:	e9 61 ff ff ff       	jmp    f010049d <cons_putc+0xba>
		cons_putc(' ');
f010053c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100541:	e8 9d fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f0100546:	b8 20 00 00 00       	mov    $0x20,%eax
f010054b:	e8 93 fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f0100550:	b8 20 00 00 00       	mov    $0x20,%eax
f0100555:	e8 89 fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f010055a:	b8 20 00 00 00       	mov    $0x20,%eax
f010055f:	e8 7f fe ff ff       	call   f01003e3 <cons_putc>
		cons_putc(' ');
f0100564:	b8 20 00 00 00       	mov    $0x20,%eax
f0100569:	e8 75 fe ff ff       	call   f01003e3 <cons_putc>
f010056e:	e9 46 ff ff ff       	jmp    f01004b9 <cons_putc+0xd6>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100573:	0f b7 05 28 62 21 f0 	movzwl 0xf0216228,%eax
f010057a:	8d 50 01             	lea    0x1(%eax),%edx
f010057d:	66 89 15 28 62 21 f0 	mov    %dx,0xf0216228
f0100584:	0f b7 c0             	movzwl %ax,%eax
f0100587:	8b 15 2c 62 21 f0    	mov    0xf021622c,%edx
f010058d:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100591:	e9 23 ff ff ff       	jmp    f01004b9 <cons_putc+0xd6>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100596:	a1 2c 62 21 f0       	mov    0xf021622c,%eax
f010059b:	83 ec 04             	sub    $0x4,%esp
f010059e:	68 00 0f 00 00       	push   $0xf00
f01005a3:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a9:	52                   	push   %edx
f01005aa:	50                   	push   %eax
f01005ab:	e8 1a 59 00 00       	call   f0105eca <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01005b0:	8b 15 2c 62 21 f0    	mov    0xf021622c,%edx
f01005b6:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01005bc:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f01005c2:	83 c4 10             	add    $0x10,%esp
f01005c5:	66 c7 00 20 07       	movw   $0x720,(%eax)
f01005ca:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005cd:	39 d0                	cmp    %edx,%eax
f01005cf:	75 f4                	jne    f01005c5 <cons_putc+0x1e2>
		crt_pos -= CRT_COLS;
f01005d1:	66 83 2d 28 62 21 f0 	subw   $0x50,0xf0216228
f01005d8:	50 
f01005d9:	e9 ea fe ff ff       	jmp    f01004c8 <cons_putc+0xe5>

f01005de <serial_intr>:
	if (serial_exists)
f01005de:	80 3d 34 62 21 f0 00 	cmpb   $0x0,0xf0216234
f01005e5:	75 02                	jne    f01005e9 <serial_intr+0xb>
f01005e7:	f3 c3                	repz ret 
{
f01005e9:	55                   	push   %ebp
f01005ea:	89 e5                	mov    %esp,%ebp
f01005ec:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005ef:	b8 64 02 10 f0       	mov    $0xf0100264,%eax
f01005f4:	e8 8a fc ff ff       	call   f0100283 <cons_intr>
}
f01005f9:	c9                   	leave  
f01005fa:	c3                   	ret    

f01005fb <kbd_intr>:
{
f01005fb:	55                   	push   %ebp
f01005fc:	89 e5                	mov    %esp,%ebp
f01005fe:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100601:	b8 c6 02 10 f0       	mov    $0xf01002c6,%eax
f0100606:	e8 78 fc ff ff       	call   f0100283 <cons_intr>
}
f010060b:	c9                   	leave  
f010060c:	c3                   	ret    

f010060d <cons_getc>:
{
f010060d:	55                   	push   %ebp
f010060e:	89 e5                	mov    %esp,%ebp
f0100610:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f0100613:	e8 c6 ff ff ff       	call   f01005de <serial_intr>
	kbd_intr();
f0100618:	e8 de ff ff ff       	call   f01005fb <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010061d:	8b 15 20 62 21 f0    	mov    0xf0216220,%edx
	return 0;
f0100623:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100628:	3b 15 24 62 21 f0    	cmp    0xf0216224,%edx
f010062e:	74 18                	je     f0100648 <cons_getc+0x3b>
		c = cons.buf[cons.rpos++];
f0100630:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100633:	89 0d 20 62 21 f0    	mov    %ecx,0xf0216220
f0100639:	0f b6 82 20 60 21 f0 	movzbl -0xfde9fe0(%edx),%eax
		if (cons.rpos == CONSBUFSIZE)
f0100640:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100646:	74 02                	je     f010064a <cons_getc+0x3d>
}
f0100648:	c9                   	leave  
f0100649:	c3                   	ret    
			cons.rpos = 0;
f010064a:	c7 05 20 62 21 f0 00 	movl   $0x0,0xf0216220
f0100651:	00 00 00 
f0100654:	eb f2                	jmp    f0100648 <cons_getc+0x3b>

f0100656 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100656:	55                   	push   %ebp
f0100657:	89 e5                	mov    %esp,%ebp
f0100659:	57                   	push   %edi
f010065a:	56                   	push   %esi
f010065b:	53                   	push   %ebx
f010065c:	83 ec 0c             	sub    $0xc,%esp
	was = *cp;
f010065f:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100666:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010066d:	5a a5 
	if (*cp != 0xA55A) {
f010066f:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100676:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010067a:	0f 84 de 00 00 00    	je     f010075e <cons_init+0x108>
		addr_6845 = MONO_BASE;
f0100680:	c7 05 30 62 21 f0 b4 	movl   $0x3b4,0xf0216230
f0100687:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010068a:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
	outb(addr_6845, 14);
f010068f:	8b 3d 30 62 21 f0    	mov    0xf0216230,%edi
f0100695:	b8 0e 00 00 00       	mov    $0xe,%eax
f010069a:	89 fa                	mov    %edi,%edx
f010069c:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010069d:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a0:	89 ca                	mov    %ecx,%edx
f01006a2:	ec                   	in     (%dx),%al
f01006a3:	0f b6 c0             	movzbl %al,%eax
f01006a6:	c1 e0 08             	shl    $0x8,%eax
f01006a9:	89 c3                	mov    %eax,%ebx
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006ab:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006b0:	89 fa                	mov    %edi,%edx
f01006b2:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006b3:	89 ca                	mov    %ecx,%edx
f01006b5:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006b6:	89 35 2c 62 21 f0    	mov    %esi,0xf021622c
	pos |= inb(addr_6845 + 1);
f01006bc:	0f b6 c0             	movzbl %al,%eax
f01006bf:	09 d8                	or     %ebx,%eax
	crt_pos = pos;
f01006c1:	66 a3 28 62 21 f0    	mov    %ax,0xf0216228
	kbd_intr();
f01006c7:	e8 2f ff ff ff       	call   f01005fb <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_KBD));
f01006cc:	83 ec 0c             	sub    $0xc,%esp
f01006cf:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f01006d6:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006db:	50                   	push   %eax
f01006dc:	e8 2f 35 00 00       	call   f0103c10 <irq_setmask_8259A>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01006e6:	b9 fa 03 00 00       	mov    $0x3fa,%ecx
f01006eb:	89 d8                	mov    %ebx,%eax
f01006ed:	89 ca                	mov    %ecx,%edx
f01006ef:	ee                   	out    %al,(%dx)
f01006f0:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006f5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006fa:	89 fa                	mov    %edi,%edx
f01006fc:	ee                   	out    %al,(%dx)
f01006fd:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100702:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100707:	ee                   	out    %al,(%dx)
f0100708:	be f9 03 00 00       	mov    $0x3f9,%esi
f010070d:	89 d8                	mov    %ebx,%eax
f010070f:	89 f2                	mov    %esi,%edx
f0100711:	ee                   	out    %al,(%dx)
f0100712:	b8 03 00 00 00       	mov    $0x3,%eax
f0100717:	89 fa                	mov    %edi,%edx
f0100719:	ee                   	out    %al,(%dx)
f010071a:	ba fc 03 00 00       	mov    $0x3fc,%edx
f010071f:	89 d8                	mov    %ebx,%eax
f0100721:	ee                   	out    %al,(%dx)
f0100722:	b8 01 00 00 00       	mov    $0x1,%eax
f0100727:	89 f2                	mov    %esi,%edx
f0100729:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010072a:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010072f:	ec                   	in     (%dx),%al
f0100730:	89 c3                	mov    %eax,%ebx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100732:	83 c4 10             	add    $0x10,%esp
f0100735:	3c ff                	cmp    $0xff,%al
f0100737:	0f 95 05 34 62 21 f0 	setne  0xf0216234
f010073e:	89 ca                	mov    %ecx,%edx
f0100740:	ec                   	in     (%dx),%al
f0100741:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100746:	ec                   	in     (%dx),%al
	if (serial_exists)
f0100747:	80 fb ff             	cmp    $0xff,%bl
f010074a:	75 2d                	jne    f0100779 <cons_init+0x123>
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
		cprintf("Serial port does not exist!\n");
f010074c:	83 ec 0c             	sub    $0xc,%esp
f010074f:	68 af 6b 10 f0       	push   $0xf0106baf
f0100754:	e8 12 36 00 00       	call   f0103d6b <cprintf>
f0100759:	83 c4 10             	add    $0x10,%esp
}
f010075c:	eb 3c                	jmp    f010079a <cons_init+0x144>
		*cp = was;
f010075e:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100765:	c7 05 30 62 21 f0 d4 	movl   $0x3d4,0xf0216230
f010076c:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010076f:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
f0100774:	e9 16 ff ff ff       	jmp    f010068f <cons_init+0x39>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<IRQ_SERIAL));
f0100779:	83 ec 0c             	sub    $0xc,%esp
f010077c:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f0100783:	25 ef ff 00 00       	and    $0xffef,%eax
f0100788:	50                   	push   %eax
f0100789:	e8 82 34 00 00       	call   f0103c10 <irq_setmask_8259A>
	if (!serial_exists)
f010078e:	83 c4 10             	add    $0x10,%esp
f0100791:	80 3d 34 62 21 f0 00 	cmpb   $0x0,0xf0216234
f0100798:	74 b2                	je     f010074c <cons_init+0xf6>
}
f010079a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010079d:	5b                   	pop    %ebx
f010079e:	5e                   	pop    %esi
f010079f:	5f                   	pop    %edi
f01007a0:	5d                   	pop    %ebp
f01007a1:	c3                   	ret    

f01007a2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007a2:	55                   	push   %ebp
f01007a3:	89 e5                	mov    %esp,%ebp
f01007a5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01007ab:	e8 33 fc ff ff       	call   f01003e3 <cons_putc>
}
f01007b0:	c9                   	leave  
f01007b1:	c3                   	ret    

f01007b2 <getchar>:

int
getchar(void)
{
f01007b2:	55                   	push   %ebp
f01007b3:	89 e5                	mov    %esp,%ebp
f01007b5:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007b8:	e8 50 fe ff ff       	call   f010060d <cons_getc>
f01007bd:	85 c0                	test   %eax,%eax
f01007bf:	74 f7                	je     f01007b8 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007c1:	c9                   	leave  
f01007c2:	c3                   	ret    

f01007c3 <iscons>:

int
iscons(int fdnum)
{
f01007c3:	55                   	push   %ebp
f01007c4:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01007cb:	5d                   	pop    %ebp
f01007cc:	c3                   	ret    

f01007cd <mon_quit>:
	return 0;
}

int
mon_quit(int argc, char **argv, struct Trapframe *tf)
{
f01007cd:	55                   	push   %ebp
f01007ce:	89 e5                	mov    %esp,%ebp
	return -1;
}
f01007d0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01007d5:	5d                   	pop    %ebp
f01007d6:	c3                   	ret    

f01007d7 <mon_help>:
{
f01007d7:	55                   	push   %ebp
f01007d8:	89 e5                	mov    %esp,%ebp
f01007da:	56                   	push   %esi
f01007db:	53                   	push   %ebx
f01007dc:	bb 00 73 10 f0       	mov    $0xf0107300,%ebx
f01007e1:	be 78 73 10 f0       	mov    $0xf0107378,%esi
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007e6:	83 ec 04             	sub    $0x4,%esp
f01007e9:	ff 73 04             	pushl  0x4(%ebx)
f01007ec:	ff 33                	pushl  (%ebx)
f01007ee:	68 00 6e 10 f0       	push   $0xf0106e00
f01007f3:	e8 73 35 00 00       	call   f0103d6b <cprintf>
f01007f8:	83 c3 0c             	add    $0xc,%ebx
	for (i = 0; i < ARRAY_SIZE(commands); i++)
f01007fb:	83 c4 10             	add    $0x10,%esp
f01007fe:	39 f3                	cmp    %esi,%ebx
f0100800:	75 e4                	jne    f01007e6 <mon_help+0xf>
}
f0100802:	b8 00 00 00 00       	mov    $0x0,%eax
f0100807:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010080a:	5b                   	pop    %ebx
f010080b:	5e                   	pop    %esi
f010080c:	5d                   	pop    %ebp
f010080d:	c3                   	ret    

f010080e <mon_kerninfo>:


int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010080e:	55                   	push   %ebp
f010080f:	89 e5                	mov    %esp,%ebp
f0100811:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100814:	68 09 6e 10 f0       	push   $0xf0106e09
f0100819:	e8 4d 35 00 00       	call   f0103d6b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010081e:	83 c4 08             	add    $0x8,%esp
f0100821:	68 0c 00 10 00       	push   $0x10000c
f0100826:	68 c8 6f 10 f0       	push   $0xf0106fc8
f010082b:	e8 3b 35 00 00       	call   f0103d6b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100830:	83 c4 0c             	add    $0xc,%esp
f0100833:	68 0c 00 10 00       	push   $0x10000c
f0100838:	68 0c 00 10 f0       	push   $0xf010000c
f010083d:	68 f0 6f 10 f0       	push   $0xf0106ff0
f0100842:	e8 24 35 00 00       	call   f0103d6b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100847:	83 c4 0c             	add    $0xc,%esp
f010084a:	68 d9 6a 10 00       	push   $0x106ad9
f010084f:	68 d9 6a 10 f0       	push   $0xf0106ad9
f0100854:	68 14 70 10 f0       	push   $0xf0107014
f0100859:	e8 0d 35 00 00       	call   f0103d6b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010085e:	83 c4 0c             	add    $0xc,%esp
f0100861:	68 00 60 21 00       	push   $0x216000
f0100866:	68 00 60 21 f0       	push   $0xf0216000
f010086b:	68 38 70 10 f0       	push   $0xf0107038
f0100870:	e8 f6 34 00 00       	call   f0103d6b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100875:	83 c4 0c             	add    $0xc,%esp
f0100878:	68 08 80 25 00       	push   $0x258008
f010087d:	68 08 80 25 f0       	push   $0xf0258008
f0100882:	68 5c 70 10 f0       	push   $0xf010705c
f0100887:	e8 df 34 00 00       	call   f0103d6b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088f:	b8 07 84 25 f0       	mov    $0xf0258407,%eax
f0100894:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100899:	c1 f8 0a             	sar    $0xa,%eax
f010089c:	50                   	push   %eax
f010089d:	68 80 70 10 f0       	push   $0xf0107080
f01008a2:	e8 c4 34 00 00       	call   f0103d6b <cprintf>
	return 0;
}
f01008a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ac:	c9                   	leave  
f01008ad:	c3                   	ret    

f01008ae <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008ae:	55                   	push   %ebp
f01008af:	89 e5                	mov    %esp,%ebp
f01008b1:	57                   	push   %edi
f01008b2:	56                   	push   %esi
f01008b3:	53                   	push   %ebx
f01008b4:	83 ec 38             	sub    $0x38,%esp
	cprintf("Stack backtrace\n");
f01008b7:	68 22 6e 10 f0       	push   $0xf0106e22
f01008bc:	e8 aa 34 00 00       	call   f0103d6b <cprintf>
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008c1:	89 e8                	mov    %ebp,%eax
f01008c3:	83 c4 10             	add    $0x10,%esp
		uint32_t arg_5 = *((uint32_t*)pointer + 1 + 5);
		//
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
				ebp_val, ret_pos, arg_1, arg_2, arg_3, arg_4, arg_5);

		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f01008c6:	8d 7d d0             	lea    -0x30(%ebp),%edi
f01008c9:	eb 06                	jmp    f01008d1 <mon_backtrace+0x23>
				eip_info.eip_file, eip_info.eip_line, 
				eip_info.eip_fn_namelen, eip_info.eip_fn_name,
				ret_pos - eip_info.eip_fn_addr);
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
			break;
		ebp_val = new_ebp_val;
f01008cb:	89 f0                	mov    %esi,%eax
		if (new_ebp_val == 0x00000000 /**inital ebp value**/)
f01008cd:	85 f6                	test   %esi,%esi
f01008cf:	74 53                	je     f0100924 <mon_backtrace+0x76>
		uint32_t new_ebp_val = *((uint32_t*)pointer);
f01008d1:	8b 30                	mov    (%eax),%esi
		uint32_t ret_pos = *((uint32_t*)pointer + 1);
f01008d3:	8b 58 04             	mov    0x4(%eax),%ebx
		cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n",
f01008d6:	ff 70 18             	pushl  0x18(%eax)
f01008d9:	ff 70 14             	pushl  0x14(%eax)
f01008dc:	ff 70 10             	pushl  0x10(%eax)
f01008df:	ff 70 0c             	pushl  0xc(%eax)
f01008e2:	ff 70 08             	pushl  0x8(%eax)
f01008e5:	53                   	push   %ebx
f01008e6:	50                   	push   %eax
f01008e7:	68 ac 70 10 f0       	push   $0xf01070ac
f01008ec:	e8 7a 34 00 00       	call   f0103d6b <cprintf>
		if (debuginfo_eip(ret_pos , &eip_info) == 0)
f01008f1:	83 c4 18             	add    $0x18,%esp
f01008f4:	57                   	push   %edi
f01008f5:	53                   	push   %ebx
f01008f6:	e8 48 4a 00 00       	call   f0105343 <debuginfo_eip>
f01008fb:	83 c4 10             	add    $0x10,%esp
f01008fe:	85 c0                	test   %eax,%eax
f0100900:	75 c9                	jne    f01008cb <mon_backtrace+0x1d>
			cprintf("         %s:%d: %.*s+%d\r\n",
f0100902:	83 ec 08             	sub    $0x8,%esp
f0100905:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f0100908:	53                   	push   %ebx
f0100909:	ff 75 d8             	pushl  -0x28(%ebp)
f010090c:	ff 75 dc             	pushl  -0x24(%ebp)
f010090f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100912:	ff 75 d0             	pushl  -0x30(%ebp)
f0100915:	68 33 6e 10 f0       	push   $0xf0106e33
f010091a:	e8 4c 34 00 00       	call   f0103d6b <cprintf>
f010091f:	83 c4 20             	add    $0x20,%esp
f0100922:	eb a7                	jmp    f01008cb <mon_backtrace+0x1d>
	}
	return 0;
}
f0100924:	b8 00 00 00 00       	mov    $0x0,%eax
f0100929:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010092c:	5b                   	pop    %ebx
f010092d:	5e                   	pop    %esi
f010092e:	5f                   	pop    %edi
f010092f:	5d                   	pop    %ebp
f0100930:	c3                   	ret    

f0100931 <mon_showmappings>:

int mon_showmappings(int argc, char** argv, struct Trapframe *tf){
f0100931:	55                   	push   %ebp
f0100932:	89 e5                	mov    %esp,%ebp
f0100934:	57                   	push   %edi
f0100935:	56                   	push   %esi
f0100936:	53                   	push   %ebx
f0100937:	83 ec 0c             	sub    $0xc,%esp
f010093a:	8b 75 08             	mov    0x8(%ebp),%esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;
	if (argc != 2 && argc != 3){
f010093d:	8d 46 fe             	lea    -0x2(%esi),%eax
f0100940:	83 f8 01             	cmp    $0x1,%eax
f0100943:	76 1d                	jbe    f0100962 <mon_showmappings+0x31>
		cprintf("Usage: showmappings ADDR1 [ADDR2]\n");
f0100945:	83 ec 0c             	sub    $0xc,%esp
f0100948:	68 e4 70 10 f0       	push   $0xf01070e4
f010094d:	e8 19 34 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100952:	83 c4 10             	add    $0x10,%esp
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
		}
	}

	return 0;
}
f0100955:	b8 00 00 00 00       	mov    $0x0,%eax
f010095a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010095d:	5b                   	pop    %ebx
f010095e:	5e                   	pop    %esi
f010095f:	5f                   	pop    %edi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    
	long begin_itr = strtol(argv[1], NULL, 16);
f0100962:	83 ec 04             	sub    $0x4,%esp
f0100965:	6a 10                	push   $0x10
f0100967:	6a 00                	push   $0x0
f0100969:	8b 45 0c             	mov    0xc(%ebp),%eax
f010096c:	ff 70 04             	pushl  0x4(%eax)
f010096f:	e8 27 56 00 00       	call   f0105f9b <strtol>
f0100974:	89 c7                	mov    %eax,%edi
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100976:	83 c4 10             	add    $0x10,%esp
f0100979:	83 fe 03             	cmp    $0x3,%esi
f010097c:	74 1a                	je     f0100998 <mon_showmappings+0x67>
	begin_itr = ROUNDUP(begin_itr, PGSIZE);
f010097e:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f0100984:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end_itr = ROUNDUP(end_itr, PGSIZE);
f010098a:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f0100990:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f0100996:	eb 33                	jmp    f01009cb <mon_showmappings+0x9a>
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f0100998:	83 ec 04             	sub    $0x4,%esp
f010099b:	6a 10                	push   $0x10
f010099d:	6a 00                	push   $0x0
f010099f:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009a2:	ff 70 08             	pushl  0x8(%eax)
f01009a5:	e8 f1 55 00 00       	call   f0105f9b <strtol>
	if (begin_itr > end_itr){
f01009aa:	83 c4 10             	add    $0x10,%esp
f01009ad:	39 c7                	cmp    %eax,%edi
f01009af:	7f cd                	jg     f010097e <mon_showmappings+0x4d>
f01009b1:	89 c2                	mov    %eax,%edx
	long begin_itr = strtol(argv[1], NULL, 16);
f01009b3:	89 f8                	mov    %edi,%eax
	long end_itr = (argc == 3? strtol(argv[2], NULL, 16): begin_itr);
f01009b5:	89 d7                	mov    %edx,%edi
f01009b7:	eb c5                	jmp    f010097e <mon_showmappings+0x4d>
			cprintf("Page doesn't exist\n");
f01009b9:	83 ec 0c             	sub    $0xc,%esp
f01009bc:	68 5f 6e 10 f0       	push   $0xf0106e5f
f01009c1:	e8 a5 33 00 00       	call   f0103d6b <cprintf>
f01009c6:	83 c4 10             	add    $0x10,%esp
	long begin_itr = strtol(argv[1], NULL, 16);
f01009c9:	89 f3                	mov    %esi,%ebx
	for (long itr = begin_itr; itr <= end_itr; itr += PGSIZE){
f01009cb:	39 fb                	cmp    %edi,%ebx
f01009cd:	7f 86                	jg     f0100955 <mon_showmappings+0x24>
		cprintf("%08x ----- %08x :", itr, itr + PGSIZE);
f01009cf:	8d b3 00 10 00 00    	lea    0x1000(%ebx),%esi
f01009d5:	83 ec 04             	sub    $0x4,%esp
f01009d8:	56                   	push   %esi
f01009d9:	53                   	push   %ebx
f01009da:	68 4d 6e 10 f0       	push   $0xf0106e4d
f01009df:	e8 87 33 00 00       	call   f0103d6b <cprintf>
		pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*)itr, false);
f01009e4:	83 c4 0c             	add    $0xc,%esp
f01009e7:	6a 00                	push   $0x0
f01009e9:	53                   	push   %ebx
f01009ea:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01009f0:	e8 c6 0a 00 00       	call   f01014bb <pgdir_walk>
f01009f5:	89 c3                	mov    %eax,%ebx
		if (pte_itr == NULL)
f01009f7:	83 c4 10             	add    $0x10,%esp
f01009fa:	85 c0                	test   %eax,%eax
f01009fc:	74 bb                	je     f01009b9 <mon_showmappings+0x88>
			cprintf("ADDR = %08x, ", PTE_ADDR(*pte_itr));
f01009fe:	83 ec 08             	sub    $0x8,%esp
f0100a01:	8b 00                	mov    (%eax),%eax
f0100a03:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a08:	50                   	push   %eax
f0100a09:	68 73 6e 10 f0       	push   $0xf0106e73
f0100a0e:	e8 58 33 00 00       	call   f0103d6b <cprintf>
			cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100a13:	83 c4 08             	add    $0x8,%esp
f0100a16:	0f b6 03             	movzbl (%ebx),%eax
f0100a19:	83 e0 01             	and    $0x1,%eax
f0100a1c:	50                   	push   %eax
f0100a1d:	68 81 6e 10 f0       	push   $0xf0106e81
f0100a22:	e8 44 33 00 00       	call   f0103d6b <cprintf>
			cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100a27:	83 c4 08             	add    $0x8,%esp
f0100a2a:	0f b6 03             	movzbl (%ebx),%eax
f0100a2d:	83 e0 02             	and    $0x2,%eax
f0100a30:	50                   	push   %eax
f0100a31:	68 90 6e 10 f0       	push   $0xf0106e90
f0100a36:	e8 30 33 00 00       	call   f0103d6b <cprintf>
			cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100a3b:	83 c4 08             	add    $0x8,%esp
f0100a3e:	0f b6 03             	movzbl (%ebx),%eax
f0100a41:	83 e0 04             	and    $0x4,%eax
f0100a44:	50                   	push   %eax
f0100a45:	68 9f 6e 10 f0       	push   $0xf0106e9f
f0100a4a:	e8 1c 33 00 00       	call   f0103d6b <cprintf>
f0100a4f:	83 c4 10             	add    $0x10,%esp
f0100a52:	e9 72 ff ff ff       	jmp    f01009c9 <mon_showmappings+0x98>

f0100a57 <mon_setperm>:

int mon_setperm(int argc, char** argv, struct Trapframe *tf){
f0100a57:	55                   	push   %ebp
f0100a58:	89 e5                	mov    %esp,%ebp
f0100a5a:	57                   	push   %edi
f0100a5b:	56                   	push   %esi
f0100a5c:	53                   	push   %ebx
f0100a5d:	83 ec 0c             	sub    $0xc,%esp
f0100a60:	8b 75 0c             	mov    0xc(%ebp),%esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 4){
f0100a63:	83 7d 08 04          	cmpl   $0x4,0x8(%ebp)
f0100a67:	74 1d                	je     f0100a86 <mon_setperm+0x2f>
		cprintf("usage: perm ADDR [add/clear] [U/W/P] or perm ADDR [set] perm_code");
f0100a69:	83 ec 0c             	sub    $0xc,%esp
f0100a6c:	68 08 71 10 f0       	push   $0xf0107108
f0100a71:	e8 f5 32 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100a76:	83 c4 10             	add    $0x10,%esp
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));

	return 0;
}
f0100a79:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a81:	5b                   	pop    %ebx
f0100a82:	5e                   	pop    %esi
f0100a83:	5f                   	pop    %edi
f0100a84:	5d                   	pop    %ebp
f0100a85:	c3                   	ret    
	long addr = strtol(argv[1], NULL, 16);
f0100a86:	83 ec 04             	sub    $0x4,%esp
f0100a89:	6a 10                	push   $0x10
f0100a8b:	6a 00                	push   $0x0
f0100a8d:	ff 76 04             	pushl  0x4(%esi)
f0100a90:	e8 06 55 00 00       	call   f0105f9b <strtol>
	pte_t* pte_itr = pgdir_walk(kern_pgdir, (void*) addr, false);
f0100a95:	83 c4 0c             	add    $0xc,%esp
f0100a98:	6a 00                	push   $0x0
f0100a9a:	50                   	push   %eax
f0100a9b:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0100aa1:	e8 15 0a 00 00       	call   f01014bb <pgdir_walk>
f0100aa6:	89 c3                	mov    %eax,%ebx
	if (pte_itr == NULL){
f0100aa8:	83 c4 10             	add    $0x10,%esp
f0100aab:	85 c0                	test   %eax,%eax
f0100aad:	0f 84 ef 00 00 00    	je     f0100ba2 <mon_setperm+0x14b>
	cprintf("Before:");
f0100ab3:	83 ec 0c             	sub    $0xc,%esp
f0100ab6:	68 c1 6e 10 f0       	push   $0xf0106ec1
f0100abb:	e8 ab 32 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100ac0:	83 c4 08             	add    $0x8,%esp
f0100ac3:	0f b6 03             	movzbl (%ebx),%eax
f0100ac6:	83 e0 01             	and    $0x1,%eax
f0100ac9:	50                   	push   %eax
f0100aca:	68 81 6e 10 f0       	push   $0xf0106e81
f0100acf:	e8 97 32 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100ad4:	83 c4 08             	add    $0x8,%esp
f0100ad7:	0f b6 03             	movzbl (%ebx),%eax
f0100ada:	83 e0 02             	and    $0x2,%eax
f0100add:	50                   	push   %eax
f0100ade:	68 90 6e 10 f0       	push   $0xf0106e90
f0100ae3:	e8 83 32 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100ae8:	83 c4 08             	add    $0x8,%esp
f0100aeb:	0f b6 03             	movzbl (%ebx),%eax
f0100aee:	83 e0 04             	and    $0x4,%eax
f0100af1:	50                   	push   %eax
f0100af2:	68 9f 6e 10 f0       	push   $0xf0106e9f
f0100af7:	e8 6f 32 00 00       	call   f0103d6b <cprintf>
	if (strcmp("set", argv[2]) == 0){
f0100afc:	83 c4 08             	add    $0x8,%esp
f0100aff:	ff 76 08             	pushl  0x8(%esi)
f0100b02:	68 c9 6e 10 f0       	push   $0xf0106ec9
f0100b07:	e8 d6 52 00 00       	call   f0105de2 <strcmp>
f0100b0c:	83 c4 10             	add    $0x10,%esp
f0100b0f:	85 c0                	test   %eax,%eax
f0100b11:	0f 84 a0 00 00 00    	je     f0100bb7 <mon_setperm+0x160>
	if (strcmp("add", argv[2]) == 0){
f0100b17:	83 ec 08             	sub    $0x8,%esp
f0100b1a:	ff 76 08             	pushl  0x8(%esi)
f0100b1d:	68 cd 6e 10 f0       	push   $0xf0106ecd
f0100b22:	e8 bb 52 00 00       	call   f0105de2 <strcmp>
f0100b27:	89 c7                	mov    %eax,%edi
f0100b29:	83 c4 10             	add    $0x10,%esp
f0100b2c:	85 c0                	test   %eax,%eax
f0100b2e:	0f 84 a6 00 00 00    	je     f0100bda <mon_setperm+0x183>
	if (strcmp("clear", argv[2]) == 0){
f0100b34:	83 ec 08             	sub    $0x8,%esp
f0100b37:	ff 76 08             	pushl  0x8(%esi)
f0100b3a:	68 d1 6e 10 f0       	push   $0xf0106ed1
f0100b3f:	e8 9e 52 00 00       	call   f0105de2 <strcmp>
f0100b44:	89 c7                	mov    %eax,%edi
f0100b46:	83 c4 10             	add    $0x10,%esp
f0100b49:	85 c0                	test   %eax,%eax
f0100b4b:	0f 84 dd 00 00 00    	je     f0100c2e <mon_setperm+0x1d7>
	cprintf("After:");
f0100b51:	83 ec 0c             	sub    $0xc,%esp
f0100b54:	68 d7 6e 10 f0       	push   $0xf0106ed7
f0100b59:	e8 0d 32 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_P = %01x, ", (uint8_t)(*pte_itr & PTE_P));
f0100b5e:	83 c4 08             	add    $0x8,%esp
f0100b61:	0f b6 03             	movzbl (%ebx),%eax
f0100b64:	83 e0 01             	and    $0x1,%eax
f0100b67:	50                   	push   %eax
f0100b68:	68 81 6e 10 f0       	push   $0xf0106e81
f0100b6d:	e8 f9 31 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_W = %01x, ", (uint8_t)(*pte_itr & PTE_W));
f0100b72:	83 c4 08             	add    $0x8,%esp
f0100b75:	0f b6 03             	movzbl (%ebx),%eax
f0100b78:	83 e0 02             	and    $0x2,%eax
f0100b7b:	50                   	push   %eax
f0100b7c:	68 90 6e 10 f0       	push   $0xf0106e90
f0100b81:	e8 e5 31 00 00       	call   f0103d6b <cprintf>
	cprintf("PTE_U = %01x\n", (uint8_t)(*pte_itr & PTE_U));
f0100b86:	83 c4 08             	add    $0x8,%esp
f0100b89:	0f b6 03             	movzbl (%ebx),%eax
f0100b8c:	83 e0 04             	and    $0x4,%eax
f0100b8f:	50                   	push   %eax
f0100b90:	68 9f 6e 10 f0       	push   $0xf0106e9f
f0100b95:	e8 d1 31 00 00       	call   f0103d6b <cprintf>
	return 0;
f0100b9a:	83 c4 10             	add    $0x10,%esp
f0100b9d:	e9 d7 fe ff ff       	jmp    f0100a79 <mon_setperm+0x22>
		cprintf("Page Doesn't Exist!");
f0100ba2:	83 ec 0c             	sub    $0xc,%esp
f0100ba5:	68 ad 6e 10 f0       	push   $0xf0106ead
f0100baa:	e8 bc 31 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100baf:	83 c4 10             	add    $0x10,%esp
f0100bb2:	e9 c2 fe ff ff       	jmp    f0100a79 <mon_setperm+0x22>
		int perm_code = strtol(argv[3], NULL, 2);
f0100bb7:	83 ec 04             	sub    $0x4,%esp
f0100bba:	6a 02                	push   $0x2
f0100bbc:	6a 00                	push   $0x0
f0100bbe:	ff 76 0c             	pushl  0xc(%esi)
f0100bc1:	e8 d5 53 00 00       	call   f0105f9b <strtol>
		*pte_itr = *pte_itr ^ (perm_code & 7) ^ (*pte_itr & 7);
f0100bc6:	8b 13                	mov    (%ebx),%edx
f0100bc8:	83 e2 f8             	and    $0xfffffff8,%edx
f0100bcb:	83 e0 07             	and    $0x7,%eax
f0100bce:	09 d0                	or     %edx,%eax
f0100bd0:	89 03                	mov    %eax,(%ebx)
f0100bd2:	83 c4 10             	add    $0x10,%esp
f0100bd5:	e9 3d ff ff ff       	jmp    f0100b17 <mon_setperm+0xc0>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100bda:	83 ec 08             	sub    $0x8,%esp
f0100bdd:	ff 76 0c             	pushl  0xc(%esi)
f0100be0:	68 d7 75 10 f0       	push   $0xf01075d7
f0100be5:	e8 f8 51 00 00       	call   f0105de2 <strcmp>
f0100bea:	83 c4 08             	add    $0x8,%esp
f0100bed:	85 c0                	test   %eax,%eax
f0100bef:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100bf3:	ff 76 0c             	pushl  0xc(%esi)
f0100bf6:	68 35 8a 10 f0       	push   $0xf0108a35
f0100bfb:	e8 e2 51 00 00       	call   f0105de2 <strcmp>
f0100c00:	83 c4 08             	add    $0x8,%esp
f0100c03:	85 c0                	test   %eax,%eax
f0100c05:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c0a:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100c0d:	ff 76 0c             	pushl  0xc(%esi)
f0100c10:	68 a7 76 10 f0       	push   $0xf01076a7
f0100c15:	e8 c8 51 00 00       	call   f0105de2 <strcmp>
f0100c1a:	83 c4 10             	add    $0x10,%esp
f0100c1d:	85 c0                	test   %eax,%eax
f0100c1f:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c24:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr | perm_code;
f0100c27:	09 3b                	or     %edi,(%ebx)
f0100c29:	e9 06 ff ff ff       	jmp    f0100b34 <mon_setperm+0xdd>
		if (strcmp("U", argv[3]) == 0) perm_code = PTE_U;
f0100c2e:	83 ec 08             	sub    $0x8,%esp
f0100c31:	ff 76 0c             	pushl  0xc(%esi)
f0100c34:	68 d7 75 10 f0       	push   $0xf01075d7
f0100c39:	e8 a4 51 00 00       	call   f0105de2 <strcmp>
f0100c3e:	83 c4 08             	add    $0x8,%esp
f0100c41:	85 c0                	test   %eax,%eax
f0100c43:	0f 44 7d 08          	cmove  0x8(%ebp),%edi
		if (strcmp("P", argv[3]) == 0) perm_code = PTE_P;
f0100c47:	ff 76 0c             	pushl  0xc(%esi)
f0100c4a:	68 35 8a 10 f0       	push   $0xf0108a35
f0100c4f:	e8 8e 51 00 00       	call   f0105de2 <strcmp>
f0100c54:	83 c4 08             	add    $0x8,%esp
f0100c57:	85 c0                	test   %eax,%eax
f0100c59:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c5e:	0f 44 f8             	cmove  %eax,%edi
		if (strcmp("W", argv[3]) == 0) perm_code = PTE_W;
f0100c61:	ff 76 0c             	pushl  0xc(%esi)
f0100c64:	68 a7 76 10 f0       	push   $0xf01076a7
f0100c69:	e8 74 51 00 00       	call   f0105de2 <strcmp>
f0100c6e:	83 c4 10             	add    $0x10,%esp
f0100c71:	85 c0                	test   %eax,%eax
f0100c73:	b8 02 00 00 00       	mov    $0x2,%eax
f0100c78:	0f 44 f8             	cmove  %eax,%edi
		*pte_itr = *pte_itr & (~perm_code);
f0100c7b:	f7 d7                	not    %edi
f0100c7d:	21 3b                	and    %edi,(%ebx)
f0100c7f:	e9 cd fe ff ff       	jmp    f0100b51 <mon_setperm+0xfa>

f0100c84 <moniter_ci>:

int moniter_ci(int argc, char** argv, struct Trapframe *tf){
f0100c84:	55                   	push   %ebp
f0100c85:	89 e5                	mov    %esp,%ebp
f0100c87:	57                   	push   %edi
f0100c88:	56                   	push   %esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
f0100c89:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100c8d:	75 22                	jne    f0100cb1 <moniter_ci+0x2d>
		cprintf("usage: c\n continue\n");
		return 0;
	}
	if (tf == NULL){
f0100c8f:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100c93:	75 2e                	jne    f0100cc3 <moniter_ci+0x3f>
		cprintf("Not in backtrace mode\n");
f0100c95:	83 ec 0c             	sub    $0xc,%esp
f0100c98:	68 f2 6e 10 f0       	push   $0xf0106ef2
f0100c9d:	e8 c9 30 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100ca2:	83 c4 10             	add    $0x10,%esp
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags &= ~0x100;
	env_run(curenv);
	return 0;
}
f0100ca5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100caa:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100cad:	5e                   	pop    %esi
f0100cae:	5f                   	pop    %edi
f0100caf:	5d                   	pop    %ebp
f0100cb0:	c3                   	ret    
		cprintf("usage: c\n continue\n");
f0100cb1:	83 ec 0c             	sub    $0xc,%esp
f0100cb4:	68 de 6e 10 f0       	push   $0xf0106ede
f0100cb9:	e8 ad 30 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100cbe:	83 c4 10             	add    $0x10,%esp
f0100cc1:	eb e2                	jmp    f0100ca5 <moniter_ci+0x21>
	curenv->env_tf = *tf;
f0100cc3:	e8 db 57 00 00       	call   f01064a3 <cpunum>
f0100cc8:	6b c0 74             	imul   $0x74,%eax,%eax
f0100ccb:	8b 90 28 70 21 f0    	mov    -0xfde8fd8(%eax),%edx
f0100cd1:	b9 11 00 00 00       	mov    $0x11,%ecx
f0100cd6:	89 d7                	mov    %edx,%edi
f0100cd8:	8b 75 10             	mov    0x10(%ebp),%esi
f0100cdb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	curenv->env_tf.tf_eflags &= ~0x100;
f0100cdd:	e8 c1 57 00 00       	call   f01064a3 <cpunum>
f0100ce2:	6b c0 74             	imul   $0x74,%eax,%eax
f0100ce5:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0100ceb:	81 60 38 ff fe ff ff 	andl   $0xfffffeff,0x38(%eax)
	env_run(curenv);
f0100cf2:	e8 ac 57 00 00       	call   f01064a3 <cpunum>
f0100cf7:	83 ec 0c             	sub    $0xc,%esp
f0100cfa:	6b c0 74             	imul   $0x74,%eax,%eax
f0100cfd:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0100d03:	e8 06 2e 00 00       	call   f0103b0e <env_run>

f0100d08 <moniter_si>:
int moniter_si(int argc, char** argv, struct Trapframe *tf){
f0100d08:	55                   	push   %ebp
f0100d09:	89 e5                	mov    %esp,%ebp
f0100d0b:	57                   	push   %edi
f0100d0c:	56                   	push   %esi
	extern pte_t* pgdir_walk(pde_t* pgdir, const void* va, int create);
	extern pde_t* kern_pgdir;

	if (argc != 1){
f0100d0d:	83 7d 08 01          	cmpl   $0x1,0x8(%ebp)
f0100d11:	75 22                	jne    f0100d35 <moniter_si+0x2d>
		cprintf("usage: si\n stepi\n");
		return 0;
	}
	if (tf == NULL){
f0100d13:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100d17:	75 2e                	jne    f0100d47 <moniter_si+0x3f>
		cprintf("Not in backtrace mode\n");
f0100d19:	83 ec 0c             	sub    $0xc,%esp
f0100d1c:	68 f2 6e 10 f0       	push   $0xf0106ef2
f0100d21:	e8 45 30 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100d26:	83 c4 10             	add    $0x10,%esp
	}
	curenv->env_tf = *tf;
	curenv->env_tf.tf_eflags |= 0x100;
	env_run(curenv);
	return 0;
}
f0100d29:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d2e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100d31:	5e                   	pop    %esi
f0100d32:	5f                   	pop    %edi
f0100d33:	5d                   	pop    %ebp
f0100d34:	c3                   	ret    
		cprintf("usage: si\n stepi\n");
f0100d35:	83 ec 0c             	sub    $0xc,%esp
f0100d38:	68 09 6f 10 f0       	push   $0xf0106f09
f0100d3d:	e8 29 30 00 00       	call   f0103d6b <cprintf>
		return 0;
f0100d42:	83 c4 10             	add    $0x10,%esp
f0100d45:	eb e2                	jmp    f0100d29 <moniter_si+0x21>
	curenv->env_tf = *tf;
f0100d47:	e8 57 57 00 00       	call   f01064a3 <cpunum>
f0100d4c:	6b c0 74             	imul   $0x74,%eax,%eax
f0100d4f:	8b 90 28 70 21 f0    	mov    -0xfde8fd8(%eax),%edx
f0100d55:	b9 11 00 00 00       	mov    $0x11,%ecx
f0100d5a:	89 d7                	mov    %edx,%edi
f0100d5c:	8b 75 10             	mov    0x10(%ebp),%esi
f0100d5f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	curenv->env_tf.tf_eflags |= 0x100;
f0100d61:	e8 3d 57 00 00       	call   f01064a3 <cpunum>
f0100d66:	6b c0 74             	imul   $0x74,%eax,%eax
f0100d69:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0100d6f:	81 48 38 00 01 00 00 	orl    $0x100,0x38(%eax)
	env_run(curenv);
f0100d76:	e8 28 57 00 00       	call   f01064a3 <cpunum>
f0100d7b:	83 ec 0c             	sub    $0xc,%esp
f0100d7e:	6b c0 74             	imul   $0x74,%eax,%eax
f0100d81:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0100d87:	e8 82 2d 00 00       	call   f0103b0e <env_run>

f0100d8c <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100d8c:	55                   	push   %ebp
f0100d8d:	89 e5                	mov    %esp,%ebp
f0100d8f:	57                   	push   %edi
f0100d90:	56                   	push   %esi
f0100d91:	53                   	push   %ebx
f0100d92:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100d95:	68 4c 71 10 f0       	push   $0xf010714c
f0100d9a:	e8 cc 2f 00 00       	call   f0103d6b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100d9f:	c7 04 24 70 71 10 f0 	movl   $0xf0107170,(%esp)
f0100da6:	e8 c0 2f 00 00       	call   f0103d6b <cprintf>

	if (tf != NULL)
f0100dab:	83 c4 10             	add    $0x10,%esp
f0100dae:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100db2:	74 57                	je     f0100e0b <monitor+0x7f>
		print_trapframe(tf);
f0100db4:	83 ec 0c             	sub    $0xc,%esp
f0100db7:	ff 75 08             	pushl  0x8(%ebp)
f0100dba:	e8 0c 37 00 00       	call   f01044cb <print_trapframe>
f0100dbf:	83 c4 10             	add    $0x10,%esp
f0100dc2:	eb 47                	jmp    f0100e0b <monitor+0x7f>
		while (*buf && strchr(WHITESPACE, *buf))
f0100dc4:	83 ec 08             	sub    $0x8,%esp
f0100dc7:	0f be c0             	movsbl %al,%eax
f0100dca:	50                   	push   %eax
f0100dcb:	68 1f 6f 10 f0       	push   $0xf0106f1f
f0100dd0:	e8 6b 50 00 00       	call   f0105e40 <strchr>
f0100dd5:	83 c4 10             	add    $0x10,%esp
f0100dd8:	85 c0                	test   %eax,%eax
f0100dda:	74 0a                	je     f0100de6 <monitor+0x5a>
			*buf++ = 0;
f0100ddc:	c6 03 00             	movb   $0x0,(%ebx)
f0100ddf:	89 f7                	mov    %esi,%edi
f0100de1:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100de4:	eb 6b                	jmp    f0100e51 <monitor+0xc5>
		if (*buf == 0)
f0100de6:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100de9:	74 73                	je     f0100e5e <monitor+0xd2>
		if (argc == MAXARGS - 1) {
f0100deb:	83 fe 0f             	cmp    $0xf,%esi
f0100dee:	74 09                	je     f0100df9 <monitor+0x6d>
		argv[argc++] = buf;
f0100df0:	8d 7e 01             	lea    0x1(%esi),%edi
f0100df3:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100df7:	eb 39                	jmp    f0100e32 <monitor+0xa6>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100df9:	83 ec 08             	sub    $0x8,%esp
f0100dfc:	6a 10                	push   $0x10
f0100dfe:	68 24 6f 10 f0       	push   $0xf0106f24
f0100e03:	e8 63 2f 00 00       	call   f0103d6b <cprintf>
f0100e08:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100e0b:	83 ec 0c             	sub    $0xc,%esp
f0100e0e:	68 1b 6f 10 f0       	push   $0xf0106f1b
f0100e13:	e8 ff 4d 00 00       	call   f0105c17 <readline>
f0100e18:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100e1a:	83 c4 10             	add    $0x10,%esp
f0100e1d:	85 c0                	test   %eax,%eax
f0100e1f:	74 ea                	je     f0100e0b <monitor+0x7f>
	argv[argc] = 0;
f0100e21:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100e28:	be 00 00 00 00       	mov    $0x0,%esi
f0100e2d:	eb 24                	jmp    f0100e53 <monitor+0xc7>
			buf++;
f0100e2f:	83 c3 01             	add    $0x1,%ebx
		while (*buf && !strchr(WHITESPACE, *buf))
f0100e32:	0f b6 03             	movzbl (%ebx),%eax
f0100e35:	84 c0                	test   %al,%al
f0100e37:	74 18                	je     f0100e51 <monitor+0xc5>
f0100e39:	83 ec 08             	sub    $0x8,%esp
f0100e3c:	0f be c0             	movsbl %al,%eax
f0100e3f:	50                   	push   %eax
f0100e40:	68 1f 6f 10 f0       	push   $0xf0106f1f
f0100e45:	e8 f6 4f 00 00       	call   f0105e40 <strchr>
f0100e4a:	83 c4 10             	add    $0x10,%esp
f0100e4d:	85 c0                	test   %eax,%eax
f0100e4f:	74 de                	je     f0100e2f <monitor+0xa3>
			*buf++ = 0;
f0100e51:	89 fe                	mov    %edi,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f0100e53:	0f b6 03             	movzbl (%ebx),%eax
f0100e56:	84 c0                	test   %al,%al
f0100e58:	0f 85 66 ff ff ff    	jne    f0100dc4 <monitor+0x38>
	argv[argc] = 0;
f0100e5e:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100e65:	00 
	if (argc == 0)
f0100e66:	85 f6                	test   %esi,%esi
f0100e68:	74 a1                	je     f0100e0b <monitor+0x7f>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100e6a:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (strcmp(argv[0], commands[i].name) == 0)
f0100e6f:	83 ec 08             	sub    $0x8,%esp
f0100e72:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100e75:	ff 34 85 00 73 10 f0 	pushl  -0xfef8d00(,%eax,4)
f0100e7c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100e7f:	e8 5e 4f 00 00       	call   f0105de2 <strcmp>
f0100e84:	83 c4 10             	add    $0x10,%esp
f0100e87:	85 c0                	test   %eax,%eax
f0100e89:	74 20                	je     f0100eab <monitor+0x11f>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100e8b:	83 c3 01             	add    $0x1,%ebx
f0100e8e:	83 fb 0a             	cmp    $0xa,%ebx
f0100e91:	75 dc                	jne    f0100e6f <monitor+0xe3>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100e93:	83 ec 08             	sub    $0x8,%esp
f0100e96:	ff 75 a8             	pushl  -0x58(%ebp)
f0100e99:	68 41 6f 10 f0       	push   $0xf0106f41
f0100e9e:	e8 c8 2e 00 00       	call   f0103d6b <cprintf>
f0100ea3:	83 c4 10             	add    $0x10,%esp
f0100ea6:	e9 60 ff ff ff       	jmp    f0100e0b <monitor+0x7f>
			return commands[i].func(argc, argv, tf);
f0100eab:	83 ec 04             	sub    $0x4,%esp
f0100eae:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100eb1:	ff 75 08             	pushl  0x8(%ebp)
f0100eb4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100eb7:	52                   	push   %edx
f0100eb8:	56                   	push   %esi
f0100eb9:	ff 14 85 08 73 10 f0 	call   *-0xfef8cf8(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ec0:	83 c4 10             	add    $0x10,%esp
f0100ec3:	85 c0                	test   %eax,%eax
f0100ec5:	0f 89 40 ff ff ff    	jns    f0100e0b <monitor+0x7f>
				break;
	}
}
f0100ecb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ece:	5b                   	pop    %ebx
f0100ecf:	5e                   	pop    %esi
f0100ed0:	5f                   	pop    %edi
f0100ed1:	5d                   	pop    %ebp
f0100ed2:	c3                   	ret    

f0100ed3 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ed3:	55                   	push   %ebp
f0100ed4:	89 e5                	mov    %esp,%ebp
f0100ed6:	56                   	push   %esi
f0100ed7:	53                   	push   %ebx
f0100ed8:	89 c6                	mov    %eax,%esi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100eda:	83 ec 0c             	sub    $0xc,%esp
f0100edd:	50                   	push   %eax
f0100ede:	e8 ff 2c 00 00       	call   f0103be2 <mc146818_read>
f0100ee3:	89 c3                	mov    %eax,%ebx
f0100ee5:	83 c6 01             	add    $0x1,%esi
f0100ee8:	89 34 24             	mov    %esi,(%esp)
f0100eeb:	e8 f2 2c 00 00       	call   f0103be2 <mc146818_read>
f0100ef0:	c1 e0 08             	shl    $0x8,%eax
f0100ef3:	09 d8                	or     %ebx,%eax
}
f0100ef5:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100ef8:	5b                   	pop    %ebx
f0100ef9:	5e                   	pop    %esi
f0100efa:	5d                   	pop    %ebp
f0100efb:	c3                   	ret    

f0100efc <boot_alloc>:
// before the page_free_list list has been set up.
// Note that when this function is called, we are still using entry_pgdir,
// which only maps the first 4MB of physical memory.
static void *
boot_alloc(uint32_t n)
{
f0100efc:	55                   	push   %ebp
f0100efd:	89 e5                	mov    %esp,%ebp
f0100eff:	53                   	push   %ebx
f0100f00:	83 ec 04             	sub    $0x4,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100f03:	83 3d 38 62 21 f0 00 	cmpl   $0x0,0xf0216238
f0100f0a:	74 40                	je     f0100f4c <boot_alloc+0x50>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.

	if (!n)
		return nextfree;
f0100f0c:	8b 1d 38 62 21 f0    	mov    0xf0216238,%ebx
	if (!n)
f0100f12:	85 c0                	test   %eax,%eax
f0100f14:	74 2f                	je     f0100f45 <boot_alloc+0x49>
	char* new_nextfree = ROUNDUP((char *)nextfree + n, PGSIZE);
f0100f16:	8b 1d 38 62 21 f0    	mov    0xf0216238,%ebx
f0100f1c:	8d 94 03 ff 0f 00 00 	lea    0xfff(%ebx,%eax,1),%edx
f0100f23:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100f29:	39 d3                	cmp    %edx,%ebx
f0100f2b:	73 32                	jae    f0100f5f <boot_alloc+0x63>
		((uintptr_t) new_nextfree <= (uintptr_t) KERNBASE + npages * PGSIZE)){
f0100f2d:	a1 88 6e 21 f0       	mov    0xf0216e88,%eax
f0100f32:	8d 88 00 00 0f 00    	lea    0xf0000(%eax),%ecx
f0100f38:	c1 e1 0c             	shl    $0xc,%ecx
	if (((uintptr_t) new_nextfree > (uintptr_t)nextfree) &&
f0100f3b:	39 d1                	cmp    %edx,%ecx
f0100f3d:	72 20                	jb     f0100f5f <boot_alloc+0x63>
		//May Alloc too much memory, and the pinter excedded 2^32
		char* result = nextfree;
		nextfree = new_nextfree;
f0100f3f:	89 15 38 62 21 f0    	mov    %edx,0xf0216238
		return (void*) result;
	}
	panic("Warning : bad alloc request");
	return NULL;
}
f0100f45:	89 d8                	mov    %ebx,%eax
f0100f47:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100f4a:	c9                   	leave  
f0100f4b:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100f4c:	ba 07 90 25 f0       	mov    $0xf0259007,%edx
f0100f51:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100f57:	89 15 38 62 21 f0    	mov    %edx,0xf0216238
f0100f5d:	eb ad                	jmp    f0100f0c <boot_alloc+0x10>
	panic("Warning : bad alloc request");
f0100f5f:	83 ec 04             	sub    $0x4,%esp
f0100f62:	68 78 73 10 f0       	push   $0xf0107378
f0100f67:	6a 79                	push   $0x79
f0100f69:	68 94 73 10 f0       	push   $0xf0107394
f0100f6e:	e8 cd f0 ff ff       	call   f0100040 <_panic>

f0100f73 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100f73:	89 d1                	mov    %edx,%ecx
f0100f75:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100f78:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100f7b:	a8 01                	test   $0x1,%al
f0100f7d:	74 52                	je     f0100fd1 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100f7f:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0100f84:	89 c1                	mov    %eax,%ecx
f0100f86:	c1 e9 0c             	shr    $0xc,%ecx
f0100f89:	3b 0d 88 6e 21 f0    	cmp    0xf0216e88,%ecx
f0100f8f:	73 25                	jae    f0100fb6 <check_va2pa+0x43>
	if (!(p[PTX(va)] & PTE_P))
f0100f91:	c1 ea 0c             	shr    $0xc,%edx
f0100f94:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100f9a:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100fa1:	89 c2                	mov    %eax,%edx
f0100fa3:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100fa6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100fab:	85 d2                	test   %edx,%edx
f0100fad:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100fb2:	0f 44 c2             	cmove  %edx,%eax
f0100fb5:	c3                   	ret    
{
f0100fb6:	55                   	push   %ebp
f0100fb7:	89 e5                	mov    %esp,%ebp
f0100fb9:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fbc:	50                   	push   %eax
f0100fbd:	68 04 6b 10 f0       	push   $0xf0106b04
f0100fc2:	68 96 03 00 00       	push   $0x396
f0100fc7:	68 94 73 10 f0       	push   $0xf0107394
f0100fcc:	e8 6f f0 ff ff       	call   f0100040 <_panic>
		return ~0;
f0100fd1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f0100fd6:	c3                   	ret    

f0100fd7 <check_page_free_list>:
{
f0100fd7:	55                   	push   %ebp
f0100fd8:	89 e5                	mov    %esp,%ebp
f0100fda:	57                   	push   %edi
f0100fdb:	56                   	push   %esi
f0100fdc:	53                   	push   %ebx
f0100fdd:	83 ec 2c             	sub    $0x2c,%esp
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fe0:	84 c0                	test   %al,%al
f0100fe2:	0f 85 86 02 00 00    	jne    f010126e <check_page_free_list+0x297>
	if (!page_free_list)
f0100fe8:	83 3d 40 62 21 f0 00 	cmpl   $0x0,0xf0216240
f0100fef:	74 0a                	je     f0100ffb <check_page_free_list+0x24>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ff1:	be 00 04 00 00       	mov    $0x400,%esi
f0100ff6:	e9 ce 02 00 00       	jmp    f01012c9 <check_page_free_list+0x2f2>
		panic("'page_free_list' is a null pointer!");
f0100ffb:	83 ec 04             	sub    $0x4,%esp
f0100ffe:	68 b8 76 10 f0       	push   $0xf01076b8
f0101003:	68 c9 02 00 00       	push   $0x2c9
f0101008:	68 94 73 10 f0       	push   $0xf0107394
f010100d:	e8 2e f0 ff ff       	call   f0100040 <_panic>
f0101012:	50                   	push   %eax
f0101013:	68 04 6b 10 f0       	push   $0xf0106b04
f0101018:	6a 58                	push   $0x58
f010101a:	68 a0 73 10 f0       	push   $0xf01073a0
f010101f:	e8 1c f0 ff ff       	call   f0100040 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101024:	8b 1b                	mov    (%ebx),%ebx
f0101026:	85 db                	test   %ebx,%ebx
f0101028:	74 41                	je     f010106b <check_page_free_list+0x94>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010102a:	89 d8                	mov    %ebx,%eax
f010102c:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0101032:	c1 f8 03             	sar    $0x3,%eax
f0101035:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0101038:	89 c2                	mov    %eax,%edx
f010103a:	c1 ea 16             	shr    $0x16,%edx
f010103d:	39 f2                	cmp    %esi,%edx
f010103f:	73 e3                	jae    f0101024 <check_page_free_list+0x4d>
	if (PGNUM(pa) >= npages)
f0101041:	89 c2                	mov    %eax,%edx
f0101043:	c1 ea 0c             	shr    $0xc,%edx
f0101046:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f010104c:	73 c4                	jae    f0101012 <check_page_free_list+0x3b>
			memset(page2kva(pp), 0x97, 128);
f010104e:	83 ec 04             	sub    $0x4,%esp
f0101051:	68 80 00 00 00       	push   $0x80
f0101056:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f010105b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101060:	50                   	push   %eax
f0101061:	e8 17 4e 00 00       	call   f0105e7d <memset>
f0101066:	83 c4 10             	add    $0x10,%esp
f0101069:	eb b9                	jmp    f0101024 <check_page_free_list+0x4d>
	first_free_page = (char *) boot_alloc(0);
f010106b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101070:	e8 87 fe ff ff       	call   f0100efc <boot_alloc>
f0101075:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101078:	8b 15 40 62 21 f0    	mov    0xf0216240,%edx
		assert(pp >= pages);
f010107e:	8b 0d 90 6e 21 f0    	mov    0xf0216e90,%ecx
		assert(pp < pages + npages);
f0101084:	a1 88 6e 21 f0       	mov    0xf0216e88,%eax
f0101089:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010108c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f010108f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101092:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0101095:	be 00 00 00 00       	mov    $0x0,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010109a:	e9 04 01 00 00       	jmp    f01011a3 <check_page_free_list+0x1cc>
		assert(pp >= pages);
f010109f:	68 ae 73 10 f0       	push   $0xf01073ae
f01010a4:	68 ba 73 10 f0       	push   $0xf01073ba
f01010a9:	68 e3 02 00 00       	push   $0x2e3
f01010ae:	68 94 73 10 f0       	push   $0xf0107394
f01010b3:	e8 88 ef ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f01010b8:	68 cf 73 10 f0       	push   $0xf01073cf
f01010bd:	68 ba 73 10 f0       	push   $0xf01073ba
f01010c2:	68 e4 02 00 00       	push   $0x2e4
f01010c7:	68 94 73 10 f0       	push   $0xf0107394
f01010cc:	e8 6f ef ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01010d1:	68 dc 76 10 f0       	push   $0xf01076dc
f01010d6:	68 ba 73 10 f0       	push   $0xf01073ba
f01010db:	68 e5 02 00 00       	push   $0x2e5
f01010e0:	68 94 73 10 f0       	push   $0xf0107394
f01010e5:	e8 56 ef ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != 0);
f01010ea:	68 e3 73 10 f0       	push   $0xf01073e3
f01010ef:	68 ba 73 10 f0       	push   $0xf01073ba
f01010f4:	68 e8 02 00 00       	push   $0x2e8
f01010f9:	68 94 73 10 f0       	push   $0xf0107394
f01010fe:	e8 3d ef ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101103:	68 f4 73 10 f0       	push   $0xf01073f4
f0101108:	68 ba 73 10 f0       	push   $0xf01073ba
f010110d:	68 e9 02 00 00       	push   $0x2e9
f0101112:	68 94 73 10 f0       	push   $0xf0107394
f0101117:	e8 24 ef ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010111c:	68 10 77 10 f0       	push   $0xf0107710
f0101121:	68 ba 73 10 f0       	push   $0xf01073ba
f0101126:	68 ea 02 00 00       	push   $0x2ea
f010112b:	68 94 73 10 f0       	push   $0xf0107394
f0101130:	e8 0b ef ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101135:	68 0d 74 10 f0       	push   $0xf010740d
f010113a:	68 ba 73 10 f0       	push   $0xf01073ba
f010113f:	68 eb 02 00 00       	push   $0x2eb
f0101144:	68 94 73 10 f0       	push   $0xf0107394
f0101149:	e8 f2 ee ff ff       	call   f0100040 <_panic>
	if (PGNUM(pa) >= npages)
f010114e:	89 c7                	mov    %eax,%edi
f0101150:	c1 ef 0c             	shr    $0xc,%edi
f0101153:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101156:	76 1b                	jbe    f0101173 <check_page_free_list+0x19c>
	return (void *)(pa + KERNBASE);
f0101158:	8d b8 00 00 00 f0    	lea    -0x10000000(%eax),%edi
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f010115e:	39 7d c8             	cmp    %edi,-0x38(%ebp)
f0101161:	77 22                	ja     f0101185 <check_page_free_list+0x1ae>
		assert(page2pa(pp) != MPENTRY_PADDR);
f0101163:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101168:	0f 84 98 00 00 00    	je     f0101206 <check_page_free_list+0x22f>
			++nfree_extmem;
f010116e:	83 c3 01             	add    $0x1,%ebx
f0101171:	eb 2e                	jmp    f01011a1 <check_page_free_list+0x1ca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101173:	50                   	push   %eax
f0101174:	68 04 6b 10 f0       	push   $0xf0106b04
f0101179:	6a 58                	push   $0x58
f010117b:	68 a0 73 10 f0       	push   $0xf01073a0
f0101180:	e8 bb ee ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101185:	68 34 77 10 f0       	push   $0xf0107734
f010118a:	68 ba 73 10 f0       	push   $0xf01073ba
f010118f:	68 ec 02 00 00       	push   $0x2ec
f0101194:	68 94 73 10 f0       	push   $0xf0107394
f0101199:	e8 a2 ee ff ff       	call   f0100040 <_panic>
			++nfree_basemem;
f010119e:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01011a1:	8b 12                	mov    (%edx),%edx
f01011a3:	85 d2                	test   %edx,%edx
f01011a5:	74 78                	je     f010121f <check_page_free_list+0x248>
		assert(pp >= pages);
f01011a7:	39 d1                	cmp    %edx,%ecx
f01011a9:	0f 87 f0 fe ff ff    	ja     f010109f <check_page_free_list+0xc8>
		assert(pp < pages + npages);
f01011af:	39 55 d4             	cmp    %edx,-0x2c(%ebp)
f01011b2:	0f 86 00 ff ff ff    	jbe    f01010b8 <check_page_free_list+0xe1>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01011b8:	89 d0                	mov    %edx,%eax
f01011ba:	2b 45 d0             	sub    -0x30(%ebp),%eax
f01011bd:	a8 07                	test   $0x7,%al
f01011bf:	0f 85 0c ff ff ff    	jne    f01010d1 <check_page_free_list+0xfa>
	return (pp - pages) << PGSHIFT;
f01011c5:	c1 f8 03             	sar    $0x3,%eax
f01011c8:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f01011cb:	85 c0                	test   %eax,%eax
f01011cd:	0f 84 17 ff ff ff    	je     f01010ea <check_page_free_list+0x113>
		assert(page2pa(pp) != IOPHYSMEM);
f01011d3:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01011d8:	0f 84 25 ff ff ff    	je     f0101103 <check_page_free_list+0x12c>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f01011de:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f01011e3:	0f 84 33 ff ff ff    	je     f010111c <check_page_free_list+0x145>
		assert(page2pa(pp) != EXTPHYSMEM);
f01011e9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01011ee:	0f 84 41 ff ff ff    	je     f0101135 <check_page_free_list+0x15e>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01011f4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01011f9:	0f 87 4f ff ff ff    	ja     f010114e <check_page_free_list+0x177>
		assert(page2pa(pp) != MPENTRY_PADDR);
f01011ff:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0101204:	75 98                	jne    f010119e <check_page_free_list+0x1c7>
f0101206:	68 27 74 10 f0       	push   $0xf0107427
f010120b:	68 ba 73 10 f0       	push   $0xf01073ba
f0101210:	68 ee 02 00 00       	push   $0x2ee
f0101215:	68 94 73 10 f0       	push   $0xf0107394
f010121a:	e8 21 ee ff ff       	call   f0100040 <_panic>
	assert(nfree_basemem > 0);
f010121f:	85 f6                	test   %esi,%esi
f0101221:	7e 19                	jle    f010123c <check_page_free_list+0x265>
	assert(nfree_extmem > 0);
f0101223:	85 db                	test   %ebx,%ebx
f0101225:	7e 2e                	jle    f0101255 <check_page_free_list+0x27e>
	cprintf("check_page_free_list() succeeded!\n");
f0101227:	83 ec 0c             	sub    $0xc,%esp
f010122a:	68 7c 77 10 f0       	push   $0xf010777c
f010122f:	e8 37 2b 00 00       	call   f0103d6b <cprintf>
}
f0101234:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101237:	5b                   	pop    %ebx
f0101238:	5e                   	pop    %esi
f0101239:	5f                   	pop    %edi
f010123a:	5d                   	pop    %ebp
f010123b:	c3                   	ret    
	assert(nfree_basemem > 0);
f010123c:	68 44 74 10 f0       	push   $0xf0107444
f0101241:	68 ba 73 10 f0       	push   $0xf01073ba
f0101246:	68 f6 02 00 00       	push   $0x2f6
f010124b:	68 94 73 10 f0       	push   $0xf0107394
f0101250:	e8 eb ed ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0101255:	68 56 74 10 f0       	push   $0xf0107456
f010125a:	68 ba 73 10 f0       	push   $0xf01073ba
f010125f:	68 f7 02 00 00       	push   $0x2f7
f0101264:	68 94 73 10 f0       	push   $0xf0107394
f0101269:	e8 d2 ed ff ff       	call   f0100040 <_panic>
	if (!page_free_list)
f010126e:	a1 40 62 21 f0       	mov    0xf0216240,%eax
f0101273:	85 c0                	test   %eax,%eax
f0101275:	0f 84 80 fd ff ff    	je     f0100ffb <check_page_free_list+0x24>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010127b:	8d 55 d8             	lea    -0x28(%ebp),%edx
f010127e:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101281:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101284:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101287:	89 c2                	mov    %eax,%edx
f0101289:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010128f:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0101295:	0f 95 c2             	setne  %dl
f0101298:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f010129b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f010129f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01012a1:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012a5:	8b 00                	mov    (%eax),%eax
f01012a7:	85 c0                	test   %eax,%eax
f01012a9:	75 dc                	jne    f0101287 <check_page_free_list+0x2b0>
		*tp[1] = 0;
f01012ab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012ae:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01012b4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01012b7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012ba:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01012bc:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01012bf:	a3 40 62 21 f0       	mov    %eax,0xf0216240
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01012c4:	be 01 00 00 00       	mov    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012c9:	8b 1d 40 62 21 f0    	mov    0xf0216240,%ebx
f01012cf:	e9 52 fd ff ff       	jmp    f0101026 <check_page_free_list+0x4f>

f01012d4 <page_init>:
{
f01012d4:	55                   	push   %ebp
f01012d5:	89 e5                	mov    %esp,%ebp
f01012d7:	53                   	push   %ebx
f01012d8:	83 ec 04             	sub    $0x4,%esp
	page_free_list = NULL;
f01012db:	c7 05 40 62 21 f0 00 	movl   $0x0,0xf0216240
f01012e2:	00 00 00 
	for (i = 0; i < npages; i++) {
f01012e5:	bb 00 00 00 00       	mov    $0x0,%ebx
f01012ea:	eb 26                	jmp    f0101312 <page_init+0x3e>
		else if (i >= IOPHYSMEM / PGSIZE && i < EXTPHYSMEM / PGSIZE){
f01012ec:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f01012f2:	83 f8 5f             	cmp    $0x5f,%eax
f01012f5:	77 43                	ja     f010133a <page_init+0x66>
			pages[i].pp_link = NULL;
f01012f7:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f01012fc:	c7 04 d8 00 00 00 00 	movl   $0x0,(%eax,%ebx,8)
			pages[i].pp_ref = 1;
f0101303:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0101308:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
	for (i = 0; i < npages; i++) {
f010130f:	83 c3 01             	add    $0x1,%ebx
f0101312:	39 1d 88 6e 21 f0    	cmp    %ebx,0xf0216e88
f0101318:	0f 86 aa 00 00 00    	jbe    f01013c8 <page_init+0xf4>
		if (i == 0){
f010131e:	85 db                	test   %ebx,%ebx
f0101320:	75 ca                	jne    f01012ec <page_init+0x18>
			pages[i].pp_link = NULL;
f0101322:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0101327:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
			pages[i].pp_ref = 1;
f010132d:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0101332:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
f0101338:	eb d5                	jmp    f010130f <page_init+0x3b>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f010133a:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101340:	77 36                	ja     f0101378 <page_init+0xa4>
		else if (i * PGSIZE == MPENTRY_PADDR){
f0101342:	89 d8                	mov    %ebx,%eax
f0101344:	c1 e0 0c             	shl    $0xc,%eax
f0101347:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010134c:	74 5d                	je     f01013ab <page_init+0xd7>
f010134e:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0101355:	89 c2                	mov    %eax,%edx
f0101357:	03 15 90 6e 21 f0    	add    0xf0216e90,%edx
f010135d:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0101363:	8b 0d 40 62 21 f0    	mov    0xf0216240,%ecx
f0101369:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f010136b:	03 05 90 6e 21 f0    	add    0xf0216e90,%eax
f0101371:	a3 40 62 21 f0       	mov    %eax,0xf0216240
f0101376:	eb 97                	jmp    f010130f <page_init+0x3b>
		else if (i >= EXTPHYSMEM / PGSIZE && i < ((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE){
f0101378:	b8 00 00 00 00       	mov    $0x0,%eax
f010137d:	e8 7a fb ff ff       	call   f0100efc <boot_alloc>
f0101382:	05 00 00 00 10       	add    $0x10000000,%eax
f0101387:	c1 e8 0c             	shr    $0xc,%eax
f010138a:	39 d8                	cmp    %ebx,%eax
f010138c:	76 b4                	jbe    f0101342 <page_init+0x6e>
			pages[i].pp_link = NULL;
f010138e:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0101393:	c7 04 d8 00 00 00 00 	movl   $0x0,(%eax,%ebx,8)
			pages[i].pp_ref = 1;
f010139a:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f010139f:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f01013a6:	e9 64 ff ff ff       	jmp    f010130f <page_init+0x3b>
			pages[i].pp_link = NULL;
f01013ab:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f01013b0:	c7 04 d8 00 00 00 00 	movl   $0x0,(%eax,%ebx,8)
			pages[i].pp_ref = 1;
f01013b7:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f01013bc:	66 c7 44 d8 04 01 00 	movw   $0x1,0x4(%eax,%ebx,8)
f01013c3:	e9 47 ff ff ff       	jmp    f010130f <page_init+0x3b>
}
f01013c8:	83 c4 04             	add    $0x4,%esp
f01013cb:	5b                   	pop    %ebx
f01013cc:	5d                   	pop    %ebp
f01013cd:	c3                   	ret    

f01013ce <page_alloc>:
{
f01013ce:	55                   	push   %ebp
f01013cf:	89 e5                	mov    %esp,%ebp
f01013d1:	53                   	push   %ebx
f01013d2:	83 ec 04             	sub    $0x4,%esp
	if (page_free_list == NULL)
f01013d5:	8b 1d 40 62 21 f0    	mov    0xf0216240,%ebx
f01013db:	85 db                	test   %ebx,%ebx
f01013dd:	74 13                	je     f01013f2 <page_alloc+0x24>
	page_free_list = page_free_list -> pp_link;
f01013df:	8b 03                	mov    (%ebx),%eax
f01013e1:	a3 40 62 21 f0       	mov    %eax,0xf0216240
	info -> pp_link = NULL;
f01013e6:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO)
f01013ec:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01013f0:	75 07                	jne    f01013f9 <page_alloc+0x2b>
}
f01013f2:	89 d8                	mov    %ebx,%eax
f01013f4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01013f7:	c9                   	leave  
f01013f8:	c3                   	ret    
f01013f9:	89 d8                	mov    %ebx,%eax
f01013fb:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0101401:	c1 f8 03             	sar    $0x3,%eax
f0101404:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101407:	89 c2                	mov    %eax,%edx
f0101409:	c1 ea 0c             	shr    $0xc,%edx
f010140c:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f0101412:	73 1a                	jae    f010142e <page_alloc+0x60>
		memset(page2kva(info), 0, PGSIZE);
f0101414:	83 ec 04             	sub    $0x4,%esp
f0101417:	68 00 10 00 00       	push   $0x1000
f010141c:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010141e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101423:	50                   	push   %eax
f0101424:	e8 54 4a 00 00       	call   f0105e7d <memset>
f0101429:	83 c4 10             	add    $0x10,%esp
f010142c:	eb c4                	jmp    f01013f2 <page_alloc+0x24>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010142e:	50                   	push   %eax
f010142f:	68 04 6b 10 f0       	push   $0xf0106b04
f0101434:	6a 58                	push   $0x58
f0101436:	68 a0 73 10 f0       	push   $0xf01073a0
f010143b:	e8 00 ec ff ff       	call   f0100040 <_panic>

f0101440 <page_free>:
{
f0101440:	55                   	push   %ebp
f0101441:	89 e5                	mov    %esp,%ebp
f0101443:	83 ec 08             	sub    $0x8,%esp
f0101446:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0)
f0101449:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010144e:	75 14                	jne    f0101464 <page_free+0x24>
	if (pp->pp_link != NULL)
f0101450:	83 38 00             	cmpl   $0x0,(%eax)
f0101453:	75 26                	jne    f010147b <page_free+0x3b>
	pp->pp_link = page_free_list;
f0101455:	8b 15 40 62 21 f0    	mov    0xf0216240,%edx
f010145b:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010145d:	a3 40 62 21 f0       	mov    %eax,0xf0216240
}
f0101462:	c9                   	leave  
f0101463:	c3                   	ret    
		panic("page_free(): pp->pp_ref is not zero!");
f0101464:	83 ec 04             	sub    $0x4,%esp
f0101467:	68 a0 77 10 f0       	push   $0xf01077a0
f010146c:	68 92 01 00 00       	push   $0x192
f0101471:	68 94 73 10 f0       	push   $0xf0107394
f0101476:	e8 c5 eb ff ff       	call   f0100040 <_panic>
		panic("page_free(): pp has already be freed!");
f010147b:	83 ec 04             	sub    $0x4,%esp
f010147e:	68 c8 77 10 f0       	push   $0xf01077c8
f0101483:	68 94 01 00 00       	push   $0x194
f0101488:	68 94 73 10 f0       	push   $0xf0107394
f010148d:	e8 ae eb ff ff       	call   f0100040 <_panic>

f0101492 <page_decref>:
{
f0101492:	55                   	push   %ebp
f0101493:	89 e5                	mov    %esp,%ebp
f0101495:	83 ec 08             	sub    $0x8,%esp
f0101498:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f010149b:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010149f:	83 e8 01             	sub    $0x1,%eax
f01014a2:	66 89 42 04          	mov    %ax,0x4(%edx)
f01014a6:	66 85 c0             	test   %ax,%ax
f01014a9:	74 02                	je     f01014ad <page_decref+0x1b>
}
f01014ab:	c9                   	leave  
f01014ac:	c3                   	ret    
		page_free(pp);
f01014ad:	83 ec 0c             	sub    $0xc,%esp
f01014b0:	52                   	push   %edx
f01014b1:	e8 8a ff ff ff       	call   f0101440 <page_free>
f01014b6:	83 c4 10             	add    $0x10,%esp
}
f01014b9:	eb f0                	jmp    f01014ab <page_decref+0x19>

f01014bb <pgdir_walk>:
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
f01014be:	56                   	push   %esi
f01014bf:	53                   	push   %ebx
f01014c0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uintptr_t* dict_ptr = pgdir + PDX(va);
f01014c3:	89 de                	mov    %ebx,%esi
f01014c5:	c1 ee 16             	shr    $0x16,%esi
f01014c8:	c1 e6 02             	shl    $0x2,%esi
f01014cb:	03 75 08             	add    0x8(%ebp),%esi
	if ((*dict_ptr) & PTE_P){
f01014ce:	8b 06                	mov    (%esi),%eax
f01014d0:	a8 01                	test   $0x1,%al
f01014d2:	74 3e                	je     f0101512 <pgdir_walk+0x57>
		return (pte_t*)(KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t));
f01014d4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01014d9:	89 c2                	mov    %eax,%edx
f01014db:	c1 ea 0c             	shr    $0xc,%edx
f01014de:	39 15 88 6e 21 f0    	cmp    %edx,0xf0216e88
f01014e4:	76 17                	jbe    f01014fd <pgdir_walk+0x42>
f01014e6:	c1 eb 0a             	shr    $0xa,%ebx
f01014e9:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f01014ef:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
}
f01014f6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01014f9:	5b                   	pop    %ebx
f01014fa:	5e                   	pop    %esi
f01014fb:	5d                   	pop    %ebp
f01014fc:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014fd:	50                   	push   %eax
f01014fe:	68 04 6b 10 f0       	push   $0xf0106b04
f0101503:	68 c1 01 00 00       	push   $0x1c1
f0101508:	68 94 73 10 f0       	push   $0xf0107394
f010150d:	e8 2e eb ff ff       	call   f0100040 <_panic>
		if (create == false)
f0101512:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101516:	74 5d                	je     f0101575 <pgdir_walk+0xba>
		struct PageInfo* page_itr = page_alloc(ALLOC_ZERO);
f0101518:	83 ec 0c             	sub    $0xc,%esp
f010151b:	6a 01                	push   $0x1
f010151d:	e8 ac fe ff ff       	call   f01013ce <page_alloc>
		if (page_itr == NULL)
f0101522:	83 c4 10             	add    $0x10,%esp
f0101525:	85 c0                	test   %eax,%eax
f0101527:	74 56                	je     f010157f <pgdir_walk+0xc4>
		page_itr -> pp_ref++;
f0101529:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010152e:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0101534:	c1 f8 03             	sar    $0x3,%eax
f0101537:	c1 e0 0c             	shl    $0xc,%eax
		*dict_ptr = page2pa(page_itr) | PTE_P | PTE_W | PTE_U;
f010153a:	89 c2                	mov    %eax,%edx
f010153c:	83 ca 07             	or     $0x7,%edx
f010153f:	89 16                	mov    %edx,(%esi)
	if (PGNUM(pa) >= npages)
f0101541:	89 c2                	mov    %eax,%edx
f0101543:	c1 ea 0c             	shr    $0xc,%edx
f0101546:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f010154c:	73 12                	jae    f0101560 <pgdir_walk+0xa5>
		return (pte_t*)(KADDR(PTE_ADDR(*dict_ptr)) + PTX(va) * sizeof(pte_t));
f010154e:	c1 eb 0a             	shr    $0xa,%ebx
f0101551:	81 e3 fc 0f 00 00    	and    $0xffc,%ebx
f0101557:	8d 84 18 00 00 00 f0 	lea    -0x10000000(%eax,%ebx,1),%eax
f010155e:	eb 96                	jmp    f01014f6 <pgdir_walk+0x3b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101560:	50                   	push   %eax
f0101561:	68 04 6b 10 f0       	push   $0xf0106b04
f0101566:	68 cd 01 00 00       	push   $0x1cd
f010156b:	68 94 73 10 f0       	push   $0xf0107394
f0101570:	e8 cb ea ff ff       	call   f0100040 <_panic>
			return NULL;
f0101575:	b8 00 00 00 00       	mov    $0x0,%eax
f010157a:	e9 77 ff ff ff       	jmp    f01014f6 <pgdir_walk+0x3b>
			return NULL;
f010157f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101584:	e9 6d ff ff ff       	jmp    f01014f6 <pgdir_walk+0x3b>

f0101589 <boot_map_region>:
{
f0101589:	55                   	push   %ebp
f010158a:	89 e5                	mov    %esp,%ebp
f010158c:	57                   	push   %edi
f010158d:	56                   	push   %esi
f010158e:	53                   	push   %ebx
f010158f:	83 ec 1c             	sub    $0x1c,%esp
f0101592:	89 c7                	mov    %eax,%edi
f0101594:	89 d6                	mov    %edx,%esi
f0101596:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f0101599:	bb 00 00 00 00       	mov    $0x0,%ebx
		*pte_itr = (pa + i) | perm | PTE_P;
f010159e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015a1:	83 c8 01             	or     $0x1,%eax
f01015a4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for (size_t i = 0; i < size; i += PGSIZE){
f01015a7:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f01015aa:	73 3f                	jae    f01015eb <boot_map_region+0x62>
		uintptr_t* pte_itr = pgdir_walk(pgdir, (void*)(va + i), true);
f01015ac:	83 ec 04             	sub    $0x4,%esp
f01015af:	6a 01                	push   $0x1
f01015b1:	8d 04 33             	lea    (%ebx,%esi,1),%eax
f01015b4:	50                   	push   %eax
f01015b5:	57                   	push   %edi
f01015b6:	e8 00 ff ff ff       	call   f01014bb <pgdir_walk>
		if (pte_itr == NULL)
f01015bb:	83 c4 10             	add    $0x10,%esp
f01015be:	85 c0                	test   %eax,%eax
f01015c0:	74 12                	je     f01015d4 <boot_map_region+0x4b>
		*pte_itr = (pa + i) | perm | PTE_P;
f01015c2:	89 da                	mov    %ebx,%edx
f01015c4:	03 55 08             	add    0x8(%ebp),%edx
f01015c7:	0b 55 e0             	or     -0x20(%ebp),%edx
f01015ca:	89 10                	mov    %edx,(%eax)
	for (size_t i = 0; i < size; i += PGSIZE){
f01015cc:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01015d2:	eb d3                	jmp    f01015a7 <boot_map_region+0x1e>
			panic("boot_map_region(): Map failed, bad virtual memory address");
f01015d4:	83 ec 04             	sub    $0x4,%esp
f01015d7:	68 f0 77 10 f0       	push   $0xf01077f0
f01015dc:	68 e3 01 00 00       	push   $0x1e3
f01015e1:	68 94 73 10 f0       	push   $0xf0107394
f01015e6:	e8 55 ea ff ff       	call   f0100040 <_panic>
}
f01015eb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01015ee:	5b                   	pop    %ebx
f01015ef:	5e                   	pop    %esi
f01015f0:	5f                   	pop    %edi
f01015f1:	5d                   	pop    %ebp
f01015f2:	c3                   	ret    

f01015f3 <page_lookup>:
{
f01015f3:	55                   	push   %ebp
f01015f4:	89 e5                	mov    %esp,%ebp
f01015f6:	53                   	push   %ebx
f01015f7:	83 ec 08             	sub    $0x8,%esp
f01015fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t* pte_itr = pgdir_walk(pgdir, va, false);
f01015fd:	6a 00                	push   $0x0
f01015ff:	ff 75 0c             	pushl  0xc(%ebp)
f0101602:	ff 75 08             	pushl  0x8(%ebp)
f0101605:	e8 b1 fe ff ff       	call   f01014bb <pgdir_walk>
	if (pte_itr == NULL)
f010160a:	83 c4 10             	add    $0x10,%esp
f010160d:	85 c0                	test   %eax,%eax
f010160f:	74 3a                	je     f010164b <page_lookup+0x58>
	if ((*pte_itr) & PTE_P){
f0101611:	f6 00 01             	testb  $0x1,(%eax)
f0101614:	74 3c                	je     f0101652 <page_lookup+0x5f>
		if (pte_store != NULL)
f0101616:	85 db                	test   %ebx,%ebx
f0101618:	74 02                	je     f010161c <page_lookup+0x29>
			*pte_store = pte_itr;
f010161a:	89 03                	mov    %eax,(%ebx)
f010161c:	8b 00                	mov    (%eax),%eax
f010161e:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101621:	39 05 88 6e 21 f0    	cmp    %eax,0xf0216e88
f0101627:	76 0e                	jbe    f0101637 <page_lookup+0x44>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101629:	8b 15 90 6e 21 f0    	mov    0xf0216e90,%edx
f010162f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f0101632:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101635:	c9                   	leave  
f0101636:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101637:	83 ec 04             	sub    $0x4,%esp
f010163a:	68 2c 78 10 f0       	push   $0xf010782c
f010163f:	6a 51                	push   $0x51
f0101641:	68 a0 73 10 f0       	push   $0xf01073a0
f0101646:	e8 f5 e9 ff ff       	call   f0100040 <_panic>
		return NULL;
f010164b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101650:	eb e0                	jmp    f0101632 <page_lookup+0x3f>
		return NULL;
f0101652:	b8 00 00 00 00       	mov    $0x0,%eax
f0101657:	eb d9                	jmp    f0101632 <page_lookup+0x3f>

f0101659 <tlb_invalidate>:
{
f0101659:	55                   	push   %ebp
f010165a:	89 e5                	mov    %esp,%ebp
f010165c:	83 ec 08             	sub    $0x8,%esp
	if (!curenv || curenv->env_pgdir == pgdir)
f010165f:	e8 3f 4e 00 00       	call   f01064a3 <cpunum>
f0101664:	6b c0 74             	imul   $0x74,%eax,%eax
f0101667:	83 b8 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%eax)
f010166e:	74 16                	je     f0101686 <tlb_invalidate+0x2d>
f0101670:	e8 2e 4e 00 00       	call   f01064a3 <cpunum>
f0101675:	6b c0 74             	imul   $0x74,%eax,%eax
f0101678:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f010167e:	8b 55 08             	mov    0x8(%ebp),%edx
f0101681:	39 50 60             	cmp    %edx,0x60(%eax)
f0101684:	75 06                	jne    f010168c <tlb_invalidate+0x33>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101686:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101689:	0f 01 38             	invlpg (%eax)
}
f010168c:	c9                   	leave  
f010168d:	c3                   	ret    

f010168e <page_remove>:
{
f010168e:	55                   	push   %ebp
f010168f:	89 e5                	mov    %esp,%ebp
f0101691:	56                   	push   %esi
f0101692:	53                   	push   %ebx
f0101693:	83 ec 14             	sub    $0x14,%esp
f0101696:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101699:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo* page_itr = page_lookup(pgdir, va, &pte_itr);
f010169c:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010169f:	50                   	push   %eax
f01016a0:	56                   	push   %esi
f01016a1:	53                   	push   %ebx
f01016a2:	e8 4c ff ff ff       	call   f01015f3 <page_lookup>
	if (page_itr == NULL)
f01016a7:	83 c4 10             	add    $0x10,%esp
f01016aa:	85 c0                	test   %eax,%eax
f01016ac:	74 26                	je     f01016d4 <page_remove+0x46>
	page_decref(page_itr);
f01016ae:	83 ec 0c             	sub    $0xc,%esp
f01016b1:	50                   	push   %eax
f01016b2:	e8 db fd ff ff       	call   f0101492 <page_decref>
	if (pte_itr != NULL)
f01016b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01016ba:	83 c4 10             	add    $0x10,%esp
f01016bd:	85 c0                	test   %eax,%eax
f01016bf:	74 06                	je     f01016c7 <page_remove+0x39>
		*pte_itr = 0;
f01016c1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01016c7:	83 ec 08             	sub    $0x8,%esp
f01016ca:	56                   	push   %esi
f01016cb:	53                   	push   %ebx
f01016cc:	e8 88 ff ff ff       	call   f0101659 <tlb_invalidate>
f01016d1:	83 c4 10             	add    $0x10,%esp
}
f01016d4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01016d7:	5b                   	pop    %ebx
f01016d8:	5e                   	pop    %esi
f01016d9:	5d                   	pop    %ebp
f01016da:	c3                   	ret    

f01016db <page_insert>:
{
f01016db:	55                   	push   %ebp
f01016dc:	89 e5                	mov    %esp,%ebp
f01016de:	57                   	push   %edi
f01016df:	56                   	push   %esi
f01016e0:	53                   	push   %ebx
f01016e1:	83 ec 10             	sub    $0x10,%esp
f01016e4:	8b 75 08             	mov    0x8(%ebp),%esi
f01016e7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte_ptr = pgdir_walk(pgdir, va, true);
f01016ea:	6a 01                	push   $0x1
f01016ec:	ff 75 10             	pushl  0x10(%ebp)
f01016ef:	56                   	push   %esi
f01016f0:	e8 c6 fd ff ff       	call   f01014bb <pgdir_walk>
	if (pte_ptr == NULL)
f01016f5:	83 c4 10             	add    $0x10,%esp
f01016f8:	85 c0                	test   %eax,%eax
f01016fa:	74 4c                	je     f0101748 <page_insert+0x6d>
f01016fc:	89 c7                	mov    %eax,%edi
	++pp->pp_ref;
f01016fe:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	if ((*pte_ptr) & PTE_P)
f0101703:	f6 00 01             	testb  $0x1,(%eax)
f0101706:	75 2f                	jne    f0101737 <page_insert+0x5c>
	return (pp - pages) << PGSHIFT;
f0101708:	2b 1d 90 6e 21 f0    	sub    0xf0216e90,%ebx
f010170e:	c1 fb 03             	sar    $0x3,%ebx
f0101711:	c1 e3 0c             	shl    $0xc,%ebx
	*pte_ptr = page2pa(pp) | perm | PTE_P;
f0101714:	8b 45 14             	mov    0x14(%ebp),%eax
f0101717:	83 c8 01             	or     $0x1,%eax
f010171a:	09 c3                	or     %eax,%ebx
f010171c:	89 1f                	mov    %ebx,(%edi)
	pde_t* dict_ptr = pgdir + PDX(va);
f010171e:	8b 45 10             	mov    0x10(%ebp),%eax
f0101721:	c1 e8 16             	shr    $0x16,%eax
	*dict_ptr |= perm;
f0101724:	8b 55 14             	mov    0x14(%ebp),%edx
f0101727:	09 14 86             	or     %edx,(%esi,%eax,4)
	return 0;
f010172a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010172f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101732:	5b                   	pop    %ebx
f0101733:	5e                   	pop    %esi
f0101734:	5f                   	pop    %edi
f0101735:	5d                   	pop    %ebp
f0101736:	c3                   	ret    
		page_remove(pgdir, va);
f0101737:	83 ec 08             	sub    $0x8,%esp
f010173a:	ff 75 10             	pushl  0x10(%ebp)
f010173d:	56                   	push   %esi
f010173e:	e8 4b ff ff ff       	call   f010168e <page_remove>
f0101743:	83 c4 10             	add    $0x10,%esp
f0101746:	eb c0                	jmp    f0101708 <page_insert+0x2d>
		return -E_NO_MEM;
f0101748:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010174d:	eb e0                	jmp    f010172f <page_insert+0x54>

f010174f <mmio_map_region>:
{
f010174f:	55                   	push   %ebp
f0101750:	89 e5                	mov    %esp,%ebp
f0101752:	53                   	push   %ebx
f0101753:	83 ec 04             	sub    $0x4,%esp
	size = ROUNDUP(size, PGSIZE);
f0101756:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101759:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f010175f:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	if (base + size > MMIOLIM)
f0101765:	8b 15 00 33 12 f0    	mov    0xf0123300,%edx
f010176b:	8d 04 1a             	lea    (%edx,%ebx,1),%eax
f010176e:	3d 00 00 c0 ef       	cmp    $0xefc00000,%eax
f0101773:	77 26                	ja     f010179b <mmio_map_region+0x4c>
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD | PTE_PWT | PTE_W);
f0101775:	83 ec 08             	sub    $0x8,%esp
f0101778:	6a 1a                	push   $0x1a
f010177a:	ff 75 08             	pushl  0x8(%ebp)
f010177d:	89 d9                	mov    %ebx,%ecx
f010177f:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0101784:	e8 00 fe ff ff       	call   f0101589 <boot_map_region>
	uintptr_t result = base;
f0101789:	a1 00 33 12 f0       	mov    0xf0123300,%eax
	base = base + size;
f010178e:	01 c3                	add    %eax,%ebx
f0101790:	89 1d 00 33 12 f0    	mov    %ebx,0xf0123300
}
f0101796:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101799:	c9                   	leave  
f010179a:	c3                   	ret    
		panic("memory overflow!");
f010179b:	83 ec 04             	sub    $0x4,%esp
f010179e:	68 67 74 10 f0       	push   $0xf0107467
f01017a3:	68 79 02 00 00       	push   $0x279
f01017a8:	68 94 73 10 f0       	push   $0xf0107394
f01017ad:	e8 8e e8 ff ff       	call   f0100040 <_panic>

f01017b2 <mem_init>:
{
f01017b2:	55                   	push   %ebp
f01017b3:	89 e5                	mov    %esp,%ebp
f01017b5:	57                   	push   %edi
f01017b6:	56                   	push   %esi
f01017b7:	53                   	push   %ebx
f01017b8:	83 ec 3c             	sub    $0x3c,%esp
	basemem = nvram_read(NVRAM_BASELO);
f01017bb:	b8 15 00 00 00       	mov    $0x15,%eax
f01017c0:	e8 0e f7 ff ff       	call   f0100ed3 <nvram_read>
f01017c5:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01017c7:	b8 17 00 00 00       	mov    $0x17,%eax
f01017cc:	e8 02 f7 ff ff       	call   f0100ed3 <nvram_read>
f01017d1:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01017d3:	b8 34 00 00 00       	mov    $0x34,%eax
f01017d8:	e8 f6 f6 ff ff       	call   f0100ed3 <nvram_read>
f01017dd:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01017e0:	85 c0                	test   %eax,%eax
f01017e2:	0f 85 db 00 00 00    	jne    f01018c3 <mem_init+0x111>
		totalmem = 1 * 1024 + extmem;
f01017e8:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01017ee:	85 f6                	test   %esi,%esi
f01017f0:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01017f3:	89 c2                	mov    %eax,%edx
f01017f5:	c1 ea 02             	shr    $0x2,%edx
f01017f8:	89 15 88 6e 21 f0    	mov    %edx,0xf0216e88
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01017fe:	89 c2                	mov    %eax,%edx
f0101800:	29 da                	sub    %ebx,%edx
f0101802:	52                   	push   %edx
f0101803:	53                   	push   %ebx
f0101804:	50                   	push   %eax
f0101805:	68 4c 78 10 f0       	push   $0xf010784c
f010180a:	e8 5c 25 00 00       	call   f0103d6b <cprintf>
	pde_t* __useless__ = (pde_t *) boot_alloc(PGSIZE);
f010180f:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101814:	e8 e3 f6 ff ff       	call   f0100efc <boot_alloc>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101819:	b8 00 10 00 00       	mov    $0x1000,%eax
f010181e:	e8 d9 f6 ff ff       	call   f0100efc <boot_alloc>
f0101823:	a3 8c 6e 21 f0       	mov    %eax,0xf0216e8c
	memset(kern_pgdir, 0, PGSIZE);
f0101828:	83 c4 0c             	add    $0xc,%esp
f010182b:	68 00 10 00 00       	push   $0x1000
f0101830:	6a 00                	push   $0x0
f0101832:	50                   	push   %eax
f0101833:	e8 45 46 00 00       	call   f0105e7d <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101838:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010183d:	83 c4 10             	add    $0x10,%esp
f0101840:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101845:	0f 86 82 00 00 00    	jbe    f01018cd <mem_init+0x11b>
	return (physaddr_t)kva - KERNBASE;
f010184b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101851:	83 ca 05             	or     $0x5,%edx
f0101854:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	size_t pagesize = npages * sizeof(struct PageInfo);
f010185a:	a1 88 6e 21 f0       	mov    0xf0216e88,%eax
f010185f:	c1 e0 03             	shl    $0x3,%eax
f0101862:	89 c6                	mov    %eax,%esi
f0101864:	89 45 cc             	mov    %eax,-0x34(%ebp)
	pages = (struct PageInfo*)boot_alloc(pagesize);
f0101867:	e8 90 f6 ff ff       	call   f0100efc <boot_alloc>
f010186c:	a3 90 6e 21 f0       	mov    %eax,0xf0216e90
	memset(pages, 0, pagesize);
f0101871:	83 ec 04             	sub    $0x4,%esp
f0101874:	56                   	push   %esi
f0101875:	6a 00                	push   $0x0
f0101877:	50                   	push   %eax
f0101878:	e8 00 46 00 00       	call   f0105e7d <memset>
	envs = (struct Env*)boot_alloc(envsize);
f010187d:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101882:	e8 75 f6 ff ff       	call   f0100efc <boot_alloc>
f0101887:	a3 44 62 21 f0       	mov    %eax,0xf0216244
	memset(envs, 0, envsize);
f010188c:	83 c4 0c             	add    $0xc,%esp
f010188f:	68 00 f0 01 00       	push   $0x1f000
f0101894:	6a 00                	push   $0x0
f0101896:	50                   	push   %eax
f0101897:	e8 e1 45 00 00       	call   f0105e7d <memset>
	page_init();
f010189c:	e8 33 fa ff ff       	call   f01012d4 <page_init>
	check_page_free_list(1);
f01018a1:	b8 01 00 00 00       	mov    $0x1,%eax
f01018a6:	e8 2c f7 ff ff       	call   f0100fd7 <check_page_free_list>
	if (!pages)
f01018ab:	83 c4 10             	add    $0x10,%esp
f01018ae:	83 3d 90 6e 21 f0 00 	cmpl   $0x0,0xf0216e90
f01018b5:	74 2b                	je     f01018e2 <mem_init+0x130>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018b7:	a1 40 62 21 f0       	mov    0xf0216240,%eax
f01018bc:	bb 00 00 00 00       	mov    $0x0,%ebx
f01018c1:	eb 3b                	jmp    f01018fe <mem_init+0x14c>
		totalmem = 16 * 1024 + ext16mem;
f01018c3:	05 00 40 00 00       	add    $0x4000,%eax
f01018c8:	e9 26 ff ff ff       	jmp    f01017f3 <mem_init+0x41>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01018cd:	50                   	push   %eax
f01018ce:	68 28 6b 10 f0       	push   $0xf0106b28
f01018d3:	68 a4 00 00 00       	push   $0xa4
f01018d8:	68 94 73 10 f0       	push   $0xf0107394
f01018dd:	e8 5e e7 ff ff       	call   f0100040 <_panic>
		panic("'pages' is a null pointer!");
f01018e2:	83 ec 04             	sub    $0x4,%esp
f01018e5:	68 78 74 10 f0       	push   $0xf0107478
f01018ea:	68 0a 03 00 00       	push   $0x30a
f01018ef:	68 94 73 10 f0       	push   $0xf0107394
f01018f4:	e8 47 e7 ff ff       	call   f0100040 <_panic>
		++nfree;
f01018f9:	83 c3 01             	add    $0x1,%ebx
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01018fc:	8b 00                	mov    (%eax),%eax
f01018fe:	85 c0                	test   %eax,%eax
f0101900:	75 f7                	jne    f01018f9 <mem_init+0x147>
	assert((pp0 = page_alloc(0)));
f0101902:	83 ec 0c             	sub    $0xc,%esp
f0101905:	6a 00                	push   $0x0
f0101907:	e8 c2 fa ff ff       	call   f01013ce <page_alloc>
f010190c:	89 c7                	mov    %eax,%edi
f010190e:	83 c4 10             	add    $0x10,%esp
f0101911:	85 c0                	test   %eax,%eax
f0101913:	0f 84 12 02 00 00    	je     f0101b2b <mem_init+0x379>
	assert((pp1 = page_alloc(0)));
f0101919:	83 ec 0c             	sub    $0xc,%esp
f010191c:	6a 00                	push   $0x0
f010191e:	e8 ab fa ff ff       	call   f01013ce <page_alloc>
f0101923:	89 c6                	mov    %eax,%esi
f0101925:	83 c4 10             	add    $0x10,%esp
f0101928:	85 c0                	test   %eax,%eax
f010192a:	0f 84 14 02 00 00    	je     f0101b44 <mem_init+0x392>
	assert((pp2 = page_alloc(0)));
f0101930:	83 ec 0c             	sub    $0xc,%esp
f0101933:	6a 00                	push   $0x0
f0101935:	e8 94 fa ff ff       	call   f01013ce <page_alloc>
f010193a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010193d:	83 c4 10             	add    $0x10,%esp
f0101940:	85 c0                	test   %eax,%eax
f0101942:	0f 84 15 02 00 00    	je     f0101b5d <mem_init+0x3ab>
	assert(pp1 && pp1 != pp0);
f0101948:	39 f7                	cmp    %esi,%edi
f010194a:	0f 84 26 02 00 00    	je     f0101b76 <mem_init+0x3c4>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101950:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101953:	39 c7                	cmp    %eax,%edi
f0101955:	0f 84 34 02 00 00    	je     f0101b8f <mem_init+0x3dd>
f010195b:	39 c6                	cmp    %eax,%esi
f010195d:	0f 84 2c 02 00 00    	je     f0101b8f <mem_init+0x3dd>
	return (pp - pages) << PGSHIFT;
f0101963:	8b 0d 90 6e 21 f0    	mov    0xf0216e90,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101969:	8b 15 88 6e 21 f0    	mov    0xf0216e88,%edx
f010196f:	c1 e2 0c             	shl    $0xc,%edx
f0101972:	89 f8                	mov    %edi,%eax
f0101974:	29 c8                	sub    %ecx,%eax
f0101976:	c1 f8 03             	sar    $0x3,%eax
f0101979:	c1 e0 0c             	shl    $0xc,%eax
f010197c:	39 d0                	cmp    %edx,%eax
f010197e:	0f 83 24 02 00 00    	jae    f0101ba8 <mem_init+0x3f6>
f0101984:	89 f0                	mov    %esi,%eax
f0101986:	29 c8                	sub    %ecx,%eax
f0101988:	c1 f8 03             	sar    $0x3,%eax
f010198b:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010198e:	39 c2                	cmp    %eax,%edx
f0101990:	0f 86 2b 02 00 00    	jbe    f0101bc1 <mem_init+0x40f>
f0101996:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101999:	29 c8                	sub    %ecx,%eax
f010199b:	c1 f8 03             	sar    $0x3,%eax
f010199e:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01019a1:	39 c2                	cmp    %eax,%edx
f01019a3:	0f 86 31 02 00 00    	jbe    f0101bda <mem_init+0x428>
	fl = page_free_list;
f01019a9:	a1 40 62 21 f0       	mov    0xf0216240,%eax
f01019ae:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01019b1:	c7 05 40 62 21 f0 00 	movl   $0x0,0xf0216240
f01019b8:	00 00 00 
	assert(!page_alloc(0));
f01019bb:	83 ec 0c             	sub    $0xc,%esp
f01019be:	6a 00                	push   $0x0
f01019c0:	e8 09 fa ff ff       	call   f01013ce <page_alloc>
f01019c5:	83 c4 10             	add    $0x10,%esp
f01019c8:	85 c0                	test   %eax,%eax
f01019ca:	0f 85 23 02 00 00    	jne    f0101bf3 <mem_init+0x441>
	page_free(pp0);
f01019d0:	83 ec 0c             	sub    $0xc,%esp
f01019d3:	57                   	push   %edi
f01019d4:	e8 67 fa ff ff       	call   f0101440 <page_free>
	page_free(pp1);
f01019d9:	89 34 24             	mov    %esi,(%esp)
f01019dc:	e8 5f fa ff ff       	call   f0101440 <page_free>
	page_free(pp2);
f01019e1:	83 c4 04             	add    $0x4,%esp
f01019e4:	ff 75 d4             	pushl  -0x2c(%ebp)
f01019e7:	e8 54 fa ff ff       	call   f0101440 <page_free>
	assert((pp0 = page_alloc(0)));
f01019ec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019f3:	e8 d6 f9 ff ff       	call   f01013ce <page_alloc>
f01019f8:	89 c6                	mov    %eax,%esi
f01019fa:	83 c4 10             	add    $0x10,%esp
f01019fd:	85 c0                	test   %eax,%eax
f01019ff:	0f 84 07 02 00 00    	je     f0101c0c <mem_init+0x45a>
	assert((pp1 = page_alloc(0)));
f0101a05:	83 ec 0c             	sub    $0xc,%esp
f0101a08:	6a 00                	push   $0x0
f0101a0a:	e8 bf f9 ff ff       	call   f01013ce <page_alloc>
f0101a0f:	89 c7                	mov    %eax,%edi
f0101a11:	83 c4 10             	add    $0x10,%esp
f0101a14:	85 c0                	test   %eax,%eax
f0101a16:	0f 84 09 02 00 00    	je     f0101c25 <mem_init+0x473>
	assert((pp2 = page_alloc(0)));
f0101a1c:	83 ec 0c             	sub    $0xc,%esp
f0101a1f:	6a 00                	push   $0x0
f0101a21:	e8 a8 f9 ff ff       	call   f01013ce <page_alloc>
f0101a26:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a29:	83 c4 10             	add    $0x10,%esp
f0101a2c:	85 c0                	test   %eax,%eax
f0101a2e:	0f 84 0a 02 00 00    	je     f0101c3e <mem_init+0x48c>
	assert(pp1 && pp1 != pp0);
f0101a34:	39 fe                	cmp    %edi,%esi
f0101a36:	0f 84 1b 02 00 00    	je     f0101c57 <mem_init+0x4a5>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a3c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a3f:	39 c7                	cmp    %eax,%edi
f0101a41:	0f 84 29 02 00 00    	je     f0101c70 <mem_init+0x4be>
f0101a47:	39 c6                	cmp    %eax,%esi
f0101a49:	0f 84 21 02 00 00    	je     f0101c70 <mem_init+0x4be>
	assert(!page_alloc(0));
f0101a4f:	83 ec 0c             	sub    $0xc,%esp
f0101a52:	6a 00                	push   $0x0
f0101a54:	e8 75 f9 ff ff       	call   f01013ce <page_alloc>
f0101a59:	83 c4 10             	add    $0x10,%esp
f0101a5c:	85 c0                	test   %eax,%eax
f0101a5e:	0f 85 25 02 00 00    	jne    f0101c89 <mem_init+0x4d7>
f0101a64:	89 f0                	mov    %esi,%eax
f0101a66:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0101a6c:	c1 f8 03             	sar    $0x3,%eax
f0101a6f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101a72:	89 c2                	mov    %eax,%edx
f0101a74:	c1 ea 0c             	shr    $0xc,%edx
f0101a77:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f0101a7d:	0f 83 1f 02 00 00    	jae    f0101ca2 <mem_init+0x4f0>
	memset(page2kva(pp0), 1, PGSIZE);
f0101a83:	83 ec 04             	sub    $0x4,%esp
f0101a86:	68 00 10 00 00       	push   $0x1000
f0101a8b:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101a8d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101a92:	50                   	push   %eax
f0101a93:	e8 e5 43 00 00       	call   f0105e7d <memset>
	page_free(pp0);
f0101a98:	89 34 24             	mov    %esi,(%esp)
f0101a9b:	e8 a0 f9 ff ff       	call   f0101440 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101aa0:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101aa7:	e8 22 f9 ff ff       	call   f01013ce <page_alloc>
f0101aac:	83 c4 10             	add    $0x10,%esp
f0101aaf:	85 c0                	test   %eax,%eax
f0101ab1:	0f 84 fd 01 00 00    	je     f0101cb4 <mem_init+0x502>
	assert(pp && pp0 == pp);
f0101ab7:	39 c6                	cmp    %eax,%esi
f0101ab9:	0f 85 0e 02 00 00    	jne    f0101ccd <mem_init+0x51b>
	return (pp - pages) << PGSHIFT;
f0101abf:	89 f2                	mov    %esi,%edx
f0101ac1:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f0101ac7:	c1 fa 03             	sar    $0x3,%edx
f0101aca:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0101acd:	89 d0                	mov    %edx,%eax
f0101acf:	c1 e8 0c             	shr    $0xc,%eax
f0101ad2:	3b 05 88 6e 21 f0    	cmp    0xf0216e88,%eax
f0101ad8:	0f 83 08 02 00 00    	jae    f0101ce6 <mem_init+0x534>
	return (void *)(pa + KERNBASE);
f0101ade:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101ae4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f0101aea:	80 38 00             	cmpb   $0x0,(%eax)
f0101aed:	0f 85 05 02 00 00    	jne    f0101cf8 <mem_init+0x546>
f0101af3:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f0101af6:	39 d0                	cmp    %edx,%eax
f0101af8:	75 f0                	jne    f0101aea <mem_init+0x338>
	page_free_list = fl;
f0101afa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101afd:	a3 40 62 21 f0       	mov    %eax,0xf0216240
	page_free(pp0);
f0101b02:	83 ec 0c             	sub    $0xc,%esp
f0101b05:	56                   	push   %esi
f0101b06:	e8 35 f9 ff ff       	call   f0101440 <page_free>
	page_free(pp1);
f0101b0b:	89 3c 24             	mov    %edi,(%esp)
f0101b0e:	e8 2d f9 ff ff       	call   f0101440 <page_free>
	page_free(pp2);
f0101b13:	83 c4 04             	add    $0x4,%esp
f0101b16:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101b19:	e8 22 f9 ff ff       	call   f0101440 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b1e:	a1 40 62 21 f0       	mov    0xf0216240,%eax
f0101b23:	83 c4 10             	add    $0x10,%esp
f0101b26:	e9 eb 01 00 00       	jmp    f0101d16 <mem_init+0x564>
	assert((pp0 = page_alloc(0)));
f0101b2b:	68 93 74 10 f0       	push   $0xf0107493
f0101b30:	68 ba 73 10 f0       	push   $0xf01073ba
f0101b35:	68 12 03 00 00       	push   $0x312
f0101b3a:	68 94 73 10 f0       	push   $0xf0107394
f0101b3f:	e8 fc e4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b44:	68 a9 74 10 f0       	push   $0xf01074a9
f0101b49:	68 ba 73 10 f0       	push   $0xf01073ba
f0101b4e:	68 13 03 00 00       	push   $0x313
f0101b53:	68 94 73 10 f0       	push   $0xf0107394
f0101b58:	e8 e3 e4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b5d:	68 bf 74 10 f0       	push   $0xf01074bf
f0101b62:	68 ba 73 10 f0       	push   $0xf01073ba
f0101b67:	68 14 03 00 00       	push   $0x314
f0101b6c:	68 94 73 10 f0       	push   $0xf0107394
f0101b71:	e8 ca e4 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101b76:	68 d5 74 10 f0       	push   $0xf01074d5
f0101b7b:	68 ba 73 10 f0       	push   $0xf01073ba
f0101b80:	68 17 03 00 00       	push   $0x317
f0101b85:	68 94 73 10 f0       	push   $0xf0107394
f0101b8a:	e8 b1 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b8f:	68 88 78 10 f0       	push   $0xf0107888
f0101b94:	68 ba 73 10 f0       	push   $0xf01073ba
f0101b99:	68 18 03 00 00       	push   $0x318
f0101b9e:	68 94 73 10 f0       	push   $0xf0107394
f0101ba3:	e8 98 e4 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101ba8:	68 e7 74 10 f0       	push   $0xf01074e7
f0101bad:	68 ba 73 10 f0       	push   $0xf01073ba
f0101bb2:	68 19 03 00 00       	push   $0x319
f0101bb7:	68 94 73 10 f0       	push   $0xf0107394
f0101bbc:	e8 7f e4 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101bc1:	68 04 75 10 f0       	push   $0xf0107504
f0101bc6:	68 ba 73 10 f0       	push   $0xf01073ba
f0101bcb:	68 1a 03 00 00       	push   $0x31a
f0101bd0:	68 94 73 10 f0       	push   $0xf0107394
f0101bd5:	e8 66 e4 ff ff       	call   f0100040 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101bda:	68 21 75 10 f0       	push   $0xf0107521
f0101bdf:	68 ba 73 10 f0       	push   $0xf01073ba
f0101be4:	68 1b 03 00 00       	push   $0x31b
f0101be9:	68 94 73 10 f0       	push   $0xf0107394
f0101bee:	e8 4d e4 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101bf3:	68 3e 75 10 f0       	push   $0xf010753e
f0101bf8:	68 ba 73 10 f0       	push   $0xf01073ba
f0101bfd:	68 22 03 00 00       	push   $0x322
f0101c02:	68 94 73 10 f0       	push   $0xf0107394
f0101c07:	e8 34 e4 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f0101c0c:	68 93 74 10 f0       	push   $0xf0107493
f0101c11:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c16:	68 29 03 00 00       	push   $0x329
f0101c1b:	68 94 73 10 f0       	push   $0xf0107394
f0101c20:	e8 1b e4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c25:	68 a9 74 10 f0       	push   $0xf01074a9
f0101c2a:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c2f:	68 2a 03 00 00       	push   $0x32a
f0101c34:	68 94 73 10 f0       	push   $0xf0107394
f0101c39:	e8 02 e4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101c3e:	68 bf 74 10 f0       	push   $0xf01074bf
f0101c43:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c48:	68 2b 03 00 00       	push   $0x32b
f0101c4d:	68 94 73 10 f0       	push   $0xf0107394
f0101c52:	e8 e9 e3 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0101c57:	68 d5 74 10 f0       	push   $0xf01074d5
f0101c5c:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c61:	68 2d 03 00 00       	push   $0x32d
f0101c66:	68 94 73 10 f0       	push   $0xf0107394
f0101c6b:	e8 d0 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c70:	68 88 78 10 f0       	push   $0xf0107888
f0101c75:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c7a:	68 2e 03 00 00       	push   $0x32e
f0101c7f:	68 94 73 10 f0       	push   $0xf0107394
f0101c84:	e8 b7 e3 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101c89:	68 3e 75 10 f0       	push   $0xf010753e
f0101c8e:	68 ba 73 10 f0       	push   $0xf01073ba
f0101c93:	68 2f 03 00 00       	push   $0x32f
f0101c98:	68 94 73 10 f0       	push   $0xf0107394
f0101c9d:	e8 9e e3 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ca2:	50                   	push   %eax
f0101ca3:	68 04 6b 10 f0       	push   $0xf0106b04
f0101ca8:	6a 58                	push   $0x58
f0101caa:	68 a0 73 10 f0       	push   $0xf01073a0
f0101caf:	e8 8c e3 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101cb4:	68 4d 75 10 f0       	push   $0xf010754d
f0101cb9:	68 ba 73 10 f0       	push   $0xf01073ba
f0101cbe:	68 34 03 00 00       	push   $0x334
f0101cc3:	68 94 73 10 f0       	push   $0xf0107394
f0101cc8:	e8 73 e3 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101ccd:	68 6b 75 10 f0       	push   $0xf010756b
f0101cd2:	68 ba 73 10 f0       	push   $0xf01073ba
f0101cd7:	68 35 03 00 00       	push   $0x335
f0101cdc:	68 94 73 10 f0       	push   $0xf0107394
f0101ce1:	e8 5a e3 ff ff       	call   f0100040 <_panic>
f0101ce6:	52                   	push   %edx
f0101ce7:	68 04 6b 10 f0       	push   $0xf0106b04
f0101cec:	6a 58                	push   $0x58
f0101cee:	68 a0 73 10 f0       	push   $0xf01073a0
f0101cf3:	e8 48 e3 ff ff       	call   f0100040 <_panic>
		assert(c[i] == 0);
f0101cf8:	68 7b 75 10 f0       	push   $0xf010757b
f0101cfd:	68 ba 73 10 f0       	push   $0xf01073ba
f0101d02:	68 38 03 00 00       	push   $0x338
f0101d07:	68 94 73 10 f0       	push   $0xf0107394
f0101d0c:	e8 2f e3 ff ff       	call   f0100040 <_panic>
		--nfree;
f0101d11:	83 eb 01             	sub    $0x1,%ebx
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101d14:	8b 00                	mov    (%eax),%eax
f0101d16:	85 c0                	test   %eax,%eax
f0101d18:	75 f7                	jne    f0101d11 <mem_init+0x55f>
	assert(nfree == 0);
f0101d1a:	85 db                	test   %ebx,%ebx
f0101d1c:	0f 85 7f 09 00 00    	jne    f01026a1 <mem_init+0xeef>
	cprintf("check_page_alloc() succeeded!\n");
f0101d22:	83 ec 0c             	sub    $0xc,%esp
f0101d25:	68 a8 78 10 f0       	push   $0xf01078a8
f0101d2a:	e8 3c 20 00 00       	call   f0103d6b <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101d2f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d36:	e8 93 f6 ff ff       	call   f01013ce <page_alloc>
f0101d3b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101d3e:	83 c4 10             	add    $0x10,%esp
f0101d41:	85 c0                	test   %eax,%eax
f0101d43:	0f 84 71 09 00 00    	je     f01026ba <mem_init+0xf08>
	assert((pp1 = page_alloc(0)));
f0101d49:	83 ec 0c             	sub    $0xc,%esp
f0101d4c:	6a 00                	push   $0x0
f0101d4e:	e8 7b f6 ff ff       	call   f01013ce <page_alloc>
f0101d53:	89 c3                	mov    %eax,%ebx
f0101d55:	83 c4 10             	add    $0x10,%esp
f0101d58:	85 c0                	test   %eax,%eax
f0101d5a:	0f 84 73 09 00 00    	je     f01026d3 <mem_init+0xf21>
	assert((pp2 = page_alloc(0)));
f0101d60:	83 ec 0c             	sub    $0xc,%esp
f0101d63:	6a 00                	push   $0x0
f0101d65:	e8 64 f6 ff ff       	call   f01013ce <page_alloc>
f0101d6a:	89 c6                	mov    %eax,%esi
f0101d6c:	83 c4 10             	add    $0x10,%esp
f0101d6f:	85 c0                	test   %eax,%eax
f0101d71:	0f 84 75 09 00 00    	je     f01026ec <mem_init+0xf3a>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101d77:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101d7a:	0f 84 85 09 00 00    	je     f0102705 <mem_init+0xf53>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d80:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d83:	0f 84 95 09 00 00    	je     f010271e <mem_init+0xf6c>
f0101d89:	39 c3                	cmp    %eax,%ebx
f0101d8b:	0f 84 8d 09 00 00    	je     f010271e <mem_init+0xf6c>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d91:	a1 40 62 21 f0       	mov    0xf0216240,%eax
f0101d96:	89 45 c8             	mov    %eax,-0x38(%ebp)
	page_free_list = 0;
f0101d99:	c7 05 40 62 21 f0 00 	movl   $0x0,0xf0216240
f0101da0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101da3:	83 ec 0c             	sub    $0xc,%esp
f0101da6:	6a 00                	push   $0x0
f0101da8:	e8 21 f6 ff ff       	call   f01013ce <page_alloc>
f0101dad:	83 c4 10             	add    $0x10,%esp
f0101db0:	85 c0                	test   %eax,%eax
f0101db2:	0f 85 7f 09 00 00    	jne    f0102737 <mem_init+0xf85>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101db8:	83 ec 04             	sub    $0x4,%esp
f0101dbb:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101dbe:	50                   	push   %eax
f0101dbf:	6a 00                	push   $0x0
f0101dc1:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0101dc7:	e8 27 f8 ff ff       	call   f01015f3 <page_lookup>
f0101dcc:	83 c4 10             	add    $0x10,%esp
f0101dcf:	85 c0                	test   %eax,%eax
f0101dd1:	0f 85 79 09 00 00    	jne    f0102750 <mem_init+0xf9e>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101dd7:	6a 02                	push   $0x2
f0101dd9:	6a 00                	push   $0x0
f0101ddb:	53                   	push   %ebx
f0101ddc:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0101de2:	e8 f4 f8 ff ff       	call   f01016db <page_insert>
f0101de7:	83 c4 10             	add    $0x10,%esp
f0101dea:	85 c0                	test   %eax,%eax
f0101dec:	0f 89 77 09 00 00    	jns    f0102769 <mem_init+0xfb7>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101df2:	83 ec 0c             	sub    $0xc,%esp
f0101df5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101df8:	e8 43 f6 ff ff       	call   f0101440 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101dfd:	6a 02                	push   $0x2
f0101dff:	6a 00                	push   $0x0
f0101e01:	53                   	push   %ebx
f0101e02:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0101e08:	e8 ce f8 ff ff       	call   f01016db <page_insert>
f0101e0d:	83 c4 20             	add    $0x20,%esp
f0101e10:	85 c0                	test   %eax,%eax
f0101e12:	0f 85 6a 09 00 00    	jne    f0102782 <mem_init+0xfd0>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e18:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
	return (pp - pages) << PGSHIFT;
f0101e1e:	8b 0d 90 6e 21 f0    	mov    0xf0216e90,%ecx
f0101e24:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0101e27:	8b 17                	mov    (%edi),%edx
f0101e29:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e2f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e32:	29 c8                	sub    %ecx,%eax
f0101e34:	c1 f8 03             	sar    $0x3,%eax
f0101e37:	c1 e0 0c             	shl    $0xc,%eax
f0101e3a:	39 c2                	cmp    %eax,%edx
f0101e3c:	0f 85 59 09 00 00    	jne    f010279b <mem_init+0xfe9>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101e42:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e47:	89 f8                	mov    %edi,%eax
f0101e49:	e8 25 f1 ff ff       	call   f0100f73 <check_va2pa>
f0101e4e:	89 da                	mov    %ebx,%edx
f0101e50:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101e53:	c1 fa 03             	sar    $0x3,%edx
f0101e56:	c1 e2 0c             	shl    $0xc,%edx
f0101e59:	39 d0                	cmp    %edx,%eax
f0101e5b:	0f 85 53 09 00 00    	jne    f01027b4 <mem_init+0x1002>
	assert(pp1->pp_ref == 1);
f0101e61:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e66:	0f 85 61 09 00 00    	jne    f01027cd <mem_init+0x101b>
	assert(pp0->pp_ref == 1);
f0101e6c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6f:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101e74:	0f 85 6c 09 00 00    	jne    f01027e6 <mem_init+0x1034>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e7a:	6a 02                	push   $0x2
f0101e7c:	68 00 10 00 00       	push   $0x1000
f0101e81:	56                   	push   %esi
f0101e82:	57                   	push   %edi
f0101e83:	e8 53 f8 ff ff       	call   f01016db <page_insert>
f0101e88:	83 c4 10             	add    $0x10,%esp
f0101e8b:	85 c0                	test   %eax,%eax
f0101e8d:	0f 85 6c 09 00 00    	jne    f01027ff <mem_init+0x104d>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e93:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e98:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0101e9d:	e8 d1 f0 ff ff       	call   f0100f73 <check_va2pa>
f0101ea2:	89 f2                	mov    %esi,%edx
f0101ea4:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f0101eaa:	c1 fa 03             	sar    $0x3,%edx
f0101ead:	c1 e2 0c             	shl    $0xc,%edx
f0101eb0:	39 d0                	cmp    %edx,%eax
f0101eb2:	0f 85 60 09 00 00    	jne    f0102818 <mem_init+0x1066>
	assert(pp2->pp_ref == 1);
f0101eb8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ebd:	0f 85 6e 09 00 00    	jne    f0102831 <mem_init+0x107f>

	// should be no free memory
	assert(!page_alloc(0));
f0101ec3:	83 ec 0c             	sub    $0xc,%esp
f0101ec6:	6a 00                	push   $0x0
f0101ec8:	e8 01 f5 ff ff       	call   f01013ce <page_alloc>
f0101ecd:	83 c4 10             	add    $0x10,%esp
f0101ed0:	85 c0                	test   %eax,%eax
f0101ed2:	0f 85 72 09 00 00    	jne    f010284a <mem_init+0x1098>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ed8:	6a 02                	push   $0x2
f0101eda:	68 00 10 00 00       	push   $0x1000
f0101edf:	56                   	push   %esi
f0101ee0:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0101ee6:	e8 f0 f7 ff ff       	call   f01016db <page_insert>
f0101eeb:	83 c4 10             	add    $0x10,%esp
f0101eee:	85 c0                	test   %eax,%eax
f0101ef0:	0f 85 6d 09 00 00    	jne    f0102863 <mem_init+0x10b1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ef6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101efb:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0101f00:	e8 6e f0 ff ff       	call   f0100f73 <check_va2pa>
f0101f05:	89 f2                	mov    %esi,%edx
f0101f07:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f0101f0d:	c1 fa 03             	sar    $0x3,%edx
f0101f10:	c1 e2 0c             	shl    $0xc,%edx
f0101f13:	39 d0                	cmp    %edx,%eax
f0101f15:	0f 85 61 09 00 00    	jne    f010287c <mem_init+0x10ca>
	assert(pp2->pp_ref == 1);
f0101f1b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f20:	0f 85 6f 09 00 00    	jne    f0102895 <mem_init+0x10e3>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f26:	83 ec 0c             	sub    $0xc,%esp
f0101f29:	6a 00                	push   $0x0
f0101f2b:	e8 9e f4 ff ff       	call   f01013ce <page_alloc>
f0101f30:	83 c4 10             	add    $0x10,%esp
f0101f33:	85 c0                	test   %eax,%eax
f0101f35:	0f 85 73 09 00 00    	jne    f01028ae <mem_init+0x10fc>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f3b:	8b 15 8c 6e 21 f0    	mov    0xf0216e8c,%edx
f0101f41:	8b 02                	mov    (%edx),%eax
f0101f43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101f48:	89 c1                	mov    %eax,%ecx
f0101f4a:	c1 e9 0c             	shr    $0xc,%ecx
f0101f4d:	3b 0d 88 6e 21 f0    	cmp    0xf0216e88,%ecx
f0101f53:	0f 83 6e 09 00 00    	jae    f01028c7 <mem_init+0x1115>
	return (void *)(pa + KERNBASE);
f0101f59:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f61:	83 ec 04             	sub    $0x4,%esp
f0101f64:	6a 00                	push   $0x0
f0101f66:	68 00 10 00 00       	push   $0x1000
f0101f6b:	52                   	push   %edx
f0101f6c:	e8 4a f5 ff ff       	call   f01014bb <pgdir_walk>
f0101f71:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101f74:	8d 51 04             	lea    0x4(%ecx),%edx
f0101f77:	83 c4 10             	add    $0x10,%esp
f0101f7a:	39 d0                	cmp    %edx,%eax
f0101f7c:	0f 85 5a 09 00 00    	jne    f01028dc <mem_init+0x112a>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f82:	6a 06                	push   $0x6
f0101f84:	68 00 10 00 00       	push   $0x1000
f0101f89:	56                   	push   %esi
f0101f8a:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0101f90:	e8 46 f7 ff ff       	call   f01016db <page_insert>
f0101f95:	83 c4 10             	add    $0x10,%esp
f0101f98:	85 c0                	test   %eax,%eax
f0101f9a:	0f 85 55 09 00 00    	jne    f01028f5 <mem_init+0x1143>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fa0:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
f0101fa6:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fab:	89 f8                	mov    %edi,%eax
f0101fad:	e8 c1 ef ff ff       	call   f0100f73 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101fb2:	89 f2                	mov    %esi,%edx
f0101fb4:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f0101fba:	c1 fa 03             	sar    $0x3,%edx
f0101fbd:	c1 e2 0c             	shl    $0xc,%edx
f0101fc0:	39 d0                	cmp    %edx,%eax
f0101fc2:	0f 85 46 09 00 00    	jne    f010290e <mem_init+0x115c>
	assert(pp2->pp_ref == 1);
f0101fc8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fcd:	0f 85 54 09 00 00    	jne    f0102927 <mem_init+0x1175>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101fd3:	83 ec 04             	sub    $0x4,%esp
f0101fd6:	6a 00                	push   $0x0
f0101fd8:	68 00 10 00 00       	push   $0x1000
f0101fdd:	57                   	push   %edi
f0101fde:	e8 d8 f4 ff ff       	call   f01014bb <pgdir_walk>
f0101fe3:	83 c4 10             	add    $0x10,%esp
f0101fe6:	f6 00 04             	testb  $0x4,(%eax)
f0101fe9:	0f 84 51 09 00 00    	je     f0102940 <mem_init+0x118e>
	assert(kern_pgdir[0] & PTE_U);
f0101fef:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0101ff4:	f6 00 04             	testb  $0x4,(%eax)
f0101ff7:	0f 84 5c 09 00 00    	je     f0102959 <mem_init+0x11a7>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ffd:	6a 02                	push   $0x2
f0101fff:	68 00 10 00 00       	push   $0x1000
f0102004:	56                   	push   %esi
f0102005:	50                   	push   %eax
f0102006:	e8 d0 f6 ff ff       	call   f01016db <page_insert>
f010200b:	83 c4 10             	add    $0x10,%esp
f010200e:	85 c0                	test   %eax,%eax
f0102010:	0f 85 5c 09 00 00    	jne    f0102972 <mem_init+0x11c0>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102016:	83 ec 04             	sub    $0x4,%esp
f0102019:	6a 00                	push   $0x0
f010201b:	68 00 10 00 00       	push   $0x1000
f0102020:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102026:	e8 90 f4 ff ff       	call   f01014bb <pgdir_walk>
f010202b:	83 c4 10             	add    $0x10,%esp
f010202e:	f6 00 02             	testb  $0x2,(%eax)
f0102031:	0f 84 54 09 00 00    	je     f010298b <mem_init+0x11d9>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102037:	83 ec 04             	sub    $0x4,%esp
f010203a:	6a 00                	push   $0x0
f010203c:	68 00 10 00 00       	push   $0x1000
f0102041:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102047:	e8 6f f4 ff ff       	call   f01014bb <pgdir_walk>
f010204c:	83 c4 10             	add    $0x10,%esp
f010204f:	f6 00 04             	testb  $0x4,(%eax)
f0102052:	0f 85 4c 09 00 00    	jne    f01029a4 <mem_init+0x11f2>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102058:	6a 02                	push   $0x2
f010205a:	68 00 00 40 00       	push   $0x400000
f010205f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102062:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102068:	e8 6e f6 ff ff       	call   f01016db <page_insert>
f010206d:	83 c4 10             	add    $0x10,%esp
f0102070:	85 c0                	test   %eax,%eax
f0102072:	0f 89 45 09 00 00    	jns    f01029bd <mem_init+0x120b>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102078:	6a 02                	push   $0x2
f010207a:	68 00 10 00 00       	push   $0x1000
f010207f:	53                   	push   %ebx
f0102080:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102086:	e8 50 f6 ff ff       	call   f01016db <page_insert>
f010208b:	83 c4 10             	add    $0x10,%esp
f010208e:	85 c0                	test   %eax,%eax
f0102090:	0f 85 40 09 00 00    	jne    f01029d6 <mem_init+0x1224>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102096:	83 ec 04             	sub    $0x4,%esp
f0102099:	6a 00                	push   $0x0
f010209b:	68 00 10 00 00       	push   $0x1000
f01020a0:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01020a6:	e8 10 f4 ff ff       	call   f01014bb <pgdir_walk>
f01020ab:	83 c4 10             	add    $0x10,%esp
f01020ae:	f6 00 04             	testb  $0x4,(%eax)
f01020b1:	0f 85 38 09 00 00    	jne    f01029ef <mem_init+0x123d>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020b7:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
f01020bd:	ba 00 00 00 00       	mov    $0x0,%edx
f01020c2:	89 f8                	mov    %edi,%eax
f01020c4:	e8 aa ee ff ff       	call   f0100f73 <check_va2pa>
f01020c9:	89 c1                	mov    %eax,%ecx
f01020cb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020ce:	89 d8                	mov    %ebx,%eax
f01020d0:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f01020d6:	c1 f8 03             	sar    $0x3,%eax
f01020d9:	c1 e0 0c             	shl    $0xc,%eax
f01020dc:	39 c1                	cmp    %eax,%ecx
f01020de:	0f 85 24 09 00 00    	jne    f0102a08 <mem_init+0x1256>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020e4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020e9:	89 f8                	mov    %edi,%eax
f01020eb:	e8 83 ee ff ff       	call   f0100f73 <check_va2pa>
f01020f0:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020f3:	0f 85 28 09 00 00    	jne    f0102a21 <mem_init+0x126f>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01020f9:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f01020fe:	0f 85 36 09 00 00    	jne    f0102a3a <mem_init+0x1288>
	assert(pp2->pp_ref == 0);
f0102104:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102109:	0f 85 44 09 00 00    	jne    f0102a53 <mem_init+0x12a1>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010210f:	83 ec 0c             	sub    $0xc,%esp
f0102112:	6a 00                	push   $0x0
f0102114:	e8 b5 f2 ff ff       	call   f01013ce <page_alloc>
f0102119:	83 c4 10             	add    $0x10,%esp
f010211c:	39 c6                	cmp    %eax,%esi
f010211e:	0f 85 48 09 00 00    	jne    f0102a6c <mem_init+0x12ba>
f0102124:	85 c0                	test   %eax,%eax
f0102126:	0f 84 40 09 00 00    	je     f0102a6c <mem_init+0x12ba>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010212c:	83 ec 08             	sub    $0x8,%esp
f010212f:	6a 00                	push   $0x0
f0102131:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102137:	e8 52 f5 ff ff       	call   f010168e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010213c:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
f0102142:	ba 00 00 00 00       	mov    $0x0,%edx
f0102147:	89 f8                	mov    %edi,%eax
f0102149:	e8 25 ee ff ff       	call   f0100f73 <check_va2pa>
f010214e:	83 c4 10             	add    $0x10,%esp
f0102151:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102154:	0f 85 2b 09 00 00    	jne    f0102a85 <mem_init+0x12d3>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010215a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010215f:	89 f8                	mov    %edi,%eax
f0102161:	e8 0d ee ff ff       	call   f0100f73 <check_va2pa>
f0102166:	89 da                	mov    %ebx,%edx
f0102168:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f010216e:	c1 fa 03             	sar    $0x3,%edx
f0102171:	c1 e2 0c             	shl    $0xc,%edx
f0102174:	39 d0                	cmp    %edx,%eax
f0102176:	0f 85 22 09 00 00    	jne    f0102a9e <mem_init+0x12ec>
	assert(pp1->pp_ref == 1);
f010217c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102181:	0f 85 30 09 00 00    	jne    f0102ab7 <mem_init+0x1305>
	assert(pp2->pp_ref == 0);
f0102187:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010218c:	0f 85 3e 09 00 00    	jne    f0102ad0 <mem_init+0x131e>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102192:	6a 00                	push   $0x0
f0102194:	68 00 10 00 00       	push   $0x1000
f0102199:	53                   	push   %ebx
f010219a:	57                   	push   %edi
f010219b:	e8 3b f5 ff ff       	call   f01016db <page_insert>
f01021a0:	83 c4 10             	add    $0x10,%esp
f01021a3:	85 c0                	test   %eax,%eax
f01021a5:	0f 85 3e 09 00 00    	jne    f0102ae9 <mem_init+0x1337>
	assert(pp1->pp_ref);
f01021ab:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021b0:	0f 84 4c 09 00 00    	je     f0102b02 <mem_init+0x1350>
	assert(pp1->pp_link == NULL);
f01021b6:	83 3b 00             	cmpl   $0x0,(%ebx)
f01021b9:	0f 85 5c 09 00 00    	jne    f0102b1b <mem_init+0x1369>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021bf:	83 ec 08             	sub    $0x8,%esp
f01021c2:	68 00 10 00 00       	push   $0x1000
f01021c7:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01021cd:	e8 bc f4 ff ff       	call   f010168e <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021d2:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
f01021d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01021dd:	89 f8                	mov    %edi,%eax
f01021df:	e8 8f ed ff ff       	call   f0100f73 <check_va2pa>
f01021e4:	83 c4 10             	add    $0x10,%esp
f01021e7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021ea:	0f 85 44 09 00 00    	jne    f0102b34 <mem_init+0x1382>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021f0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021f5:	89 f8                	mov    %edi,%eax
f01021f7:	e8 77 ed ff ff       	call   f0100f73 <check_va2pa>
f01021fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021ff:	0f 85 48 09 00 00    	jne    f0102b4d <mem_init+0x139b>
	assert(pp1->pp_ref == 0);
f0102205:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010220a:	0f 85 56 09 00 00    	jne    f0102b66 <mem_init+0x13b4>
	assert(pp2->pp_ref == 0);
f0102210:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102215:	0f 85 64 09 00 00    	jne    f0102b7f <mem_init+0x13cd>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010221b:	83 ec 0c             	sub    $0xc,%esp
f010221e:	6a 00                	push   $0x0
f0102220:	e8 a9 f1 ff ff       	call   f01013ce <page_alloc>
f0102225:	83 c4 10             	add    $0x10,%esp
f0102228:	85 c0                	test   %eax,%eax
f010222a:	0f 84 68 09 00 00    	je     f0102b98 <mem_init+0x13e6>
f0102230:	39 c3                	cmp    %eax,%ebx
f0102232:	0f 85 60 09 00 00    	jne    f0102b98 <mem_init+0x13e6>

	// should be no free memory
	assert(!page_alloc(0));
f0102238:	83 ec 0c             	sub    $0xc,%esp
f010223b:	6a 00                	push   $0x0
f010223d:	e8 8c f1 ff ff       	call   f01013ce <page_alloc>
f0102242:	83 c4 10             	add    $0x10,%esp
f0102245:	85 c0                	test   %eax,%eax
f0102247:	0f 85 64 09 00 00    	jne    f0102bb1 <mem_init+0x13ff>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010224d:	8b 0d 8c 6e 21 f0    	mov    0xf0216e8c,%ecx
f0102253:	8b 11                	mov    (%ecx),%edx
f0102255:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010225b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010225e:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0102264:	c1 f8 03             	sar    $0x3,%eax
f0102267:	c1 e0 0c             	shl    $0xc,%eax
f010226a:	39 c2                	cmp    %eax,%edx
f010226c:	0f 85 58 09 00 00    	jne    f0102bca <mem_init+0x1418>
	kern_pgdir[0] = 0;
f0102272:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102278:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010227b:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102280:	0f 85 5d 09 00 00    	jne    f0102be3 <mem_init+0x1431>
	pp0->pp_ref = 0;
f0102286:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102289:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010228f:	83 ec 0c             	sub    $0xc,%esp
f0102292:	50                   	push   %eax
f0102293:	e8 a8 f1 ff ff       	call   f0101440 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102298:	83 c4 0c             	add    $0xc,%esp
f010229b:	6a 01                	push   $0x1
f010229d:	68 00 10 40 00       	push   $0x401000
f01022a2:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01022a8:	e8 0e f2 ff ff       	call   f01014bb <pgdir_walk>
f01022ad:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01022b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01022b3:	8b 0d 8c 6e 21 f0    	mov    0xf0216e8c,%ecx
f01022b9:	8b 51 04             	mov    0x4(%ecx),%edx
f01022bc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01022c2:	8b 3d 88 6e 21 f0    	mov    0xf0216e88,%edi
f01022c8:	89 d0                	mov    %edx,%eax
f01022ca:	c1 e8 0c             	shr    $0xc,%eax
f01022cd:	83 c4 10             	add    $0x10,%esp
f01022d0:	39 f8                	cmp    %edi,%eax
f01022d2:	0f 83 24 09 00 00    	jae    f0102bfc <mem_init+0x144a>
	assert(ptep == ptep1 + PTX(va));
f01022d8:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01022de:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01022e1:	0f 85 2a 09 00 00    	jne    f0102c11 <mem_init+0x145f>
	kern_pgdir[PDX(va)] = 0;
f01022e7:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f01022ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f1:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f01022f7:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f01022fd:	c1 f8 03             	sar    $0x3,%eax
f0102300:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102303:	89 c2                	mov    %eax,%edx
f0102305:	c1 ea 0c             	shr    $0xc,%edx
f0102308:	39 d7                	cmp    %edx,%edi
f010230a:	0f 86 1a 09 00 00    	jbe    f0102c2a <mem_init+0x1478>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102310:	83 ec 04             	sub    $0x4,%esp
f0102313:	68 00 10 00 00       	push   $0x1000
f0102318:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010231d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102322:	50                   	push   %eax
f0102323:	e8 55 3b 00 00       	call   f0105e7d <memset>
	page_free(pp0);
f0102328:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010232b:	89 3c 24             	mov    %edi,(%esp)
f010232e:	e8 0d f1 ff ff       	call   f0101440 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102333:	83 c4 0c             	add    $0xc,%esp
f0102336:	6a 01                	push   $0x1
f0102338:	6a 00                	push   $0x0
f010233a:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102340:	e8 76 f1 ff ff       	call   f01014bb <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f0102345:	89 fa                	mov    %edi,%edx
f0102347:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f010234d:	c1 fa 03             	sar    $0x3,%edx
f0102350:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0102353:	89 d0                	mov    %edx,%eax
f0102355:	c1 e8 0c             	shr    $0xc,%eax
f0102358:	83 c4 10             	add    $0x10,%esp
f010235b:	3b 05 88 6e 21 f0    	cmp    0xf0216e88,%eax
f0102361:	0f 83 d5 08 00 00    	jae    f0102c3c <mem_init+0x148a>
	return (void *)(pa + KERNBASE);
f0102367:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010236d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102370:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102376:	f6 00 01             	testb  $0x1,(%eax)
f0102379:	0f 85 cf 08 00 00    	jne    f0102c4e <mem_init+0x149c>
f010237f:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102382:	39 d0                	cmp    %edx,%eax
f0102384:	75 f0                	jne    f0102376 <mem_init+0xbc4>
	kern_pgdir[0] = 0;
f0102386:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f010238b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102391:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102394:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010239a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010239d:	89 0d 40 62 21 f0    	mov    %ecx,0xf0216240

	// free the pages we took
	page_free(pp0);
f01023a3:	83 ec 0c             	sub    $0xc,%esp
f01023a6:	50                   	push   %eax
f01023a7:	e8 94 f0 ff ff       	call   f0101440 <page_free>
	page_free(pp1);
f01023ac:	89 1c 24             	mov    %ebx,(%esp)
f01023af:	e8 8c f0 ff ff       	call   f0101440 <page_free>
	page_free(pp2);
f01023b4:	89 34 24             	mov    %esi,(%esp)
f01023b7:	e8 84 f0 ff ff       	call   f0101440 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01023bc:	83 c4 08             	add    $0x8,%esp
f01023bf:	68 01 10 00 00       	push   $0x1001
f01023c4:	6a 00                	push   $0x0
f01023c6:	e8 84 f3 ff ff       	call   f010174f <mmio_map_region>
f01023cb:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01023cd:	83 c4 08             	add    $0x8,%esp
f01023d0:	68 00 10 00 00       	push   $0x1000
f01023d5:	6a 00                	push   $0x0
f01023d7:	e8 73 f3 ff ff       	call   f010174f <mmio_map_region>
f01023dc:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f01023de:	8d 83 00 20 00 00    	lea    0x2000(%ebx),%eax
f01023e4:	83 c4 10             	add    $0x10,%esp
f01023e7:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01023ed:	0f 86 74 08 00 00    	jbe    f0102c67 <mem_init+0x14b5>
f01023f3:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01023f8:	0f 87 69 08 00 00    	ja     f0102c67 <mem_init+0x14b5>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f01023fe:	8d 96 00 20 00 00    	lea    0x2000(%esi),%edx
f0102404:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f010240a:	0f 87 70 08 00 00    	ja     f0102c80 <mem_init+0x14ce>
f0102410:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102416:	0f 86 64 08 00 00    	jbe    f0102c80 <mem_init+0x14ce>
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010241c:	89 da                	mov    %ebx,%edx
f010241e:	09 f2                	or     %esi,%edx
f0102420:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102426:	0f 85 6d 08 00 00    	jne    f0102c99 <mem_init+0x14e7>
	// check that they don't overlap
	assert(mm1 + 8192 <= mm2);
f010242c:	39 c6                	cmp    %eax,%esi
f010242e:	0f 82 7e 08 00 00    	jb     f0102cb2 <mem_init+0x1500>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102434:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
f010243a:	89 da                	mov    %ebx,%edx
f010243c:	89 f8                	mov    %edi,%eax
f010243e:	e8 30 eb ff ff       	call   f0100f73 <check_va2pa>
f0102443:	85 c0                	test   %eax,%eax
f0102445:	0f 85 80 08 00 00    	jne    f0102ccb <mem_init+0x1519>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f010244b:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102451:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102454:	89 c2                	mov    %eax,%edx
f0102456:	89 f8                	mov    %edi,%eax
f0102458:	e8 16 eb ff ff       	call   f0100f73 <check_va2pa>
f010245d:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102462:	0f 85 7c 08 00 00    	jne    f0102ce4 <mem_init+0x1532>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102468:	89 f2                	mov    %esi,%edx
f010246a:	89 f8                	mov    %edi,%eax
f010246c:	e8 02 eb ff ff       	call   f0100f73 <check_va2pa>
f0102471:	85 c0                	test   %eax,%eax
f0102473:	0f 85 84 08 00 00    	jne    f0102cfd <mem_init+0x154b>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102479:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f010247f:	89 f8                	mov    %edi,%eax
f0102481:	e8 ed ea ff ff       	call   f0100f73 <check_va2pa>
f0102486:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102489:	0f 85 87 08 00 00    	jne    f0102d16 <mem_init+0x1564>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010248f:	83 ec 04             	sub    $0x4,%esp
f0102492:	6a 00                	push   $0x0
f0102494:	53                   	push   %ebx
f0102495:	57                   	push   %edi
f0102496:	e8 20 f0 ff ff       	call   f01014bb <pgdir_walk>
f010249b:	83 c4 10             	add    $0x10,%esp
f010249e:	f6 00 1a             	testb  $0x1a,(%eax)
f01024a1:	0f 84 88 08 00 00    	je     f0102d2f <mem_init+0x157d>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f01024a7:	83 ec 04             	sub    $0x4,%esp
f01024aa:	6a 00                	push   $0x0
f01024ac:	53                   	push   %ebx
f01024ad:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01024b3:	e8 03 f0 ff ff       	call   f01014bb <pgdir_walk>
f01024b8:	83 c4 10             	add    $0x10,%esp
f01024bb:	f6 00 04             	testb  $0x4,(%eax)
f01024be:	0f 85 84 08 00 00    	jne    f0102d48 <mem_init+0x1596>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f01024c4:	83 ec 04             	sub    $0x4,%esp
f01024c7:	6a 00                	push   $0x0
f01024c9:	53                   	push   %ebx
f01024ca:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01024d0:	e8 e6 ef ff ff       	call   f01014bb <pgdir_walk>
f01024d5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f01024db:	83 c4 0c             	add    $0xc,%esp
f01024de:	6a 00                	push   $0x0
f01024e0:	ff 75 d4             	pushl  -0x2c(%ebp)
f01024e3:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01024e9:	e8 cd ef ff ff       	call   f01014bb <pgdir_walk>
f01024ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01024f4:	83 c4 0c             	add    $0xc,%esp
f01024f7:	6a 00                	push   $0x0
f01024f9:	56                   	push   %esi
f01024fa:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0102500:	e8 b6 ef ff ff       	call   f01014bb <pgdir_walk>
f0102505:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010250b:	c7 04 24 6e 76 10 f0 	movl   $0xf010766e,(%esp)
f0102512:	e8 54 18 00 00       	call   f0103d6b <cprintf>
	boot_map_region(kern_pgdir, UPAGES, pagesize, PADDR(pages), PTE_P | PTE_U);
f0102517:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
	if ((uint32_t)kva < KERNBASE)
f010251c:	83 c4 10             	add    $0x10,%esp
f010251f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102524:	0f 86 37 08 00 00    	jbe    f0102d61 <mem_init+0x15af>
f010252a:	83 ec 08             	sub    $0x8,%esp
f010252d:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010252f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102534:	50                   	push   %eax
f0102535:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102538:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010253d:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0102542:	e8 42 f0 ff ff       	call   f0101589 <boot_map_region>
	boot_map_region(kern_pgdir, UENVS, envsize, PADDR(envs), PTE_U | PTE_P);
f0102547:	a1 44 62 21 f0       	mov    0xf0216244,%eax
	if ((uint32_t)kva < KERNBASE)
f010254c:	83 c4 10             	add    $0x10,%esp
f010254f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102554:	0f 86 1c 08 00 00    	jbe    f0102d76 <mem_init+0x15c4>
f010255a:	83 ec 08             	sub    $0x8,%esp
f010255d:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f010255f:	05 00 00 00 10       	add    $0x10000000,%eax
f0102564:	50                   	push   %eax
f0102565:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010256a:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010256f:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0102574:	e8 10 f0 ff ff       	call   f0101589 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102579:	83 c4 10             	add    $0x10,%esp
f010257c:	b8 00 90 11 f0       	mov    $0xf0119000,%eax
f0102581:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102586:	0f 86 ff 07 00 00    	jbe    f0102d8b <mem_init+0x15d9>
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f010258c:	83 ec 08             	sub    $0x8,%esp
f010258f:	6a 02                	push   $0x2
f0102591:	68 00 90 11 00       	push   $0x119000
f0102596:	b9 00 80 00 00       	mov    $0x8000,%ecx
f010259b:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01025a0:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f01025a5:	e8 df ef ff ff       	call   f0101589 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, 0Xffffffff - KERNBASE, 0, PTE_W);
f01025aa:	83 c4 08             	add    $0x8,%esp
f01025ad:	6a 02                	push   $0x2
f01025af:	6a 00                	push   $0x0
f01025b1:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01025b6:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01025bb:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f01025c0:	e8 c4 ef ff ff       	call   f0101589 <boot_map_region>
f01025c5:	c7 45 cc 00 80 21 f0 	movl   $0xf0218000,-0x34(%ebp)
f01025cc:	bf 00 80 25 f0       	mov    $0xf0258000,%edi
f01025d1:	83 c4 10             	add    $0x10,%esp
f01025d4:	bb 00 80 21 f0       	mov    $0xf0218000,%ebx
f01025d9:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01025de:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01025e4:	0f 86 b6 07 00 00    	jbe    f0102da0 <mem_init+0x15ee>
		boot_map_region(kern_pgdir, kstacktop_i - KSTKSIZE, KSTKSIZE,
f01025ea:	83 ec 08             	sub    $0x8,%esp
f01025ed:	6a 03                	push   $0x3
f01025ef:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01025f5:	50                   	push   %eax
f01025f6:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01025fb:	89 f2                	mov    %esi,%edx
f01025fd:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0102602:	e8 82 ef ff ff       	call   f0101589 <boot_map_region>
f0102607:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f010260d:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	for (int i = 0; i < NCPU; i++){
f0102613:	83 c4 10             	add    $0x10,%esp
f0102616:	39 fb                	cmp    %edi,%ebx
f0102618:	75 c4                	jne    f01025de <mem_init+0xe2c>
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f010261a:	83 ec 08             	sub    $0x8,%esp
f010261d:	6a 02                	push   $0x2
f010261f:	6a 00                	push   $0x0
f0102621:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102626:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010262b:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
f0102630:	e8 54 ef ff ff       	call   f0101589 <boot_map_region>
	pgdir = kern_pgdir;
f0102635:	8b 3d 8c 6e 21 f0    	mov    0xf0216e8c,%edi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010263b:	a1 88 6e 21 f0       	mov    0xf0216e88,%eax
f0102640:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102643:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f010264a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010264f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102652:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0102657:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010265a:	89 45 d0             	mov    %eax,-0x30(%ebp)
	return (physaddr_t)kva - KERNBASE;
f010265d:	8d b0 00 00 00 10    	lea    0x10000000(%eax),%esi
f0102663:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102666:	bb 00 00 00 00       	mov    $0x0,%ebx
f010266b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f010266e:	0f 86 71 07 00 00    	jbe    f0102de5 <mem_init+0x1633>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102674:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f010267a:	89 f8                	mov    %edi,%eax
f010267c:	e8 f2 e8 ff ff       	call   f0100f73 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102681:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102688:	0f 86 27 07 00 00    	jbe    f0102db5 <mem_init+0x1603>
f010268e:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102691:	39 d0                	cmp    %edx,%eax
f0102693:	0f 85 33 07 00 00    	jne    f0102dcc <mem_init+0x161a>
	for (i = 0; i < n; i += PGSIZE)
f0102699:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010269f:	eb ca                	jmp    f010266b <mem_init+0xeb9>
	assert(nfree == 0);
f01026a1:	68 85 75 10 f0       	push   $0xf0107585
f01026a6:	68 ba 73 10 f0       	push   $0xf01073ba
f01026ab:	68 45 03 00 00       	push   $0x345
f01026b0:	68 94 73 10 f0       	push   $0xf0107394
f01026b5:	e8 86 d9 ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f01026ba:	68 93 74 10 f0       	push   $0xf0107493
f01026bf:	68 ba 73 10 f0       	push   $0xf01073ba
f01026c4:	68 ab 03 00 00       	push   $0x3ab
f01026c9:	68 94 73 10 f0       	push   $0xf0107394
f01026ce:	e8 6d d9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01026d3:	68 a9 74 10 f0       	push   $0xf01074a9
f01026d8:	68 ba 73 10 f0       	push   $0xf01073ba
f01026dd:	68 ac 03 00 00       	push   $0x3ac
f01026e2:	68 94 73 10 f0       	push   $0xf0107394
f01026e7:	e8 54 d9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01026ec:	68 bf 74 10 f0       	push   $0xf01074bf
f01026f1:	68 ba 73 10 f0       	push   $0xf01073ba
f01026f6:	68 ad 03 00 00       	push   $0x3ad
f01026fb:	68 94 73 10 f0       	push   $0xf0107394
f0102700:	e8 3b d9 ff ff       	call   f0100040 <_panic>
	assert(pp1 && pp1 != pp0);
f0102705:	68 d5 74 10 f0       	push   $0xf01074d5
f010270a:	68 ba 73 10 f0       	push   $0xf01073ba
f010270f:	68 b0 03 00 00       	push   $0x3b0
f0102714:	68 94 73 10 f0       	push   $0xf0107394
f0102719:	e8 22 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010271e:	68 88 78 10 f0       	push   $0xf0107888
f0102723:	68 ba 73 10 f0       	push   $0xf01073ba
f0102728:	68 b1 03 00 00       	push   $0x3b1
f010272d:	68 94 73 10 f0       	push   $0xf0107394
f0102732:	e8 09 d9 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102737:	68 3e 75 10 f0       	push   $0xf010753e
f010273c:	68 ba 73 10 f0       	push   $0xf01073ba
f0102741:	68 b8 03 00 00       	push   $0x3b8
f0102746:	68 94 73 10 f0       	push   $0xf0107394
f010274b:	e8 f0 d8 ff ff       	call   f0100040 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102750:	68 c8 78 10 f0       	push   $0xf01078c8
f0102755:	68 ba 73 10 f0       	push   $0xf01073ba
f010275a:	68 bb 03 00 00       	push   $0x3bb
f010275f:	68 94 73 10 f0       	push   $0xf0107394
f0102764:	e8 d7 d8 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102769:	68 00 79 10 f0       	push   $0xf0107900
f010276e:	68 ba 73 10 f0       	push   $0xf01073ba
f0102773:	68 be 03 00 00       	push   $0x3be
f0102778:	68 94 73 10 f0       	push   $0xf0107394
f010277d:	e8 be d8 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102782:	68 30 79 10 f0       	push   $0xf0107930
f0102787:	68 ba 73 10 f0       	push   $0xf01073ba
f010278c:	68 c2 03 00 00       	push   $0x3c2
f0102791:	68 94 73 10 f0       	push   $0xf0107394
f0102796:	e8 a5 d8 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010279b:	68 60 79 10 f0       	push   $0xf0107960
f01027a0:	68 ba 73 10 f0       	push   $0xf01073ba
f01027a5:	68 c3 03 00 00       	push   $0x3c3
f01027aa:	68 94 73 10 f0       	push   $0xf0107394
f01027af:	e8 8c d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01027b4:	68 88 79 10 f0       	push   $0xf0107988
f01027b9:	68 ba 73 10 f0       	push   $0xf01073ba
f01027be:	68 c4 03 00 00       	push   $0x3c4
f01027c3:	68 94 73 10 f0       	push   $0xf0107394
f01027c8:	e8 73 d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01027cd:	68 90 75 10 f0       	push   $0xf0107590
f01027d2:	68 ba 73 10 f0       	push   $0xf01073ba
f01027d7:	68 c5 03 00 00       	push   $0x3c5
f01027dc:	68 94 73 10 f0       	push   $0xf0107394
f01027e1:	e8 5a d8 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01027e6:	68 a1 75 10 f0       	push   $0xf01075a1
f01027eb:	68 ba 73 10 f0       	push   $0xf01073ba
f01027f0:	68 c6 03 00 00       	push   $0x3c6
f01027f5:	68 94 73 10 f0       	push   $0xf0107394
f01027fa:	e8 41 d8 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01027ff:	68 b8 79 10 f0       	push   $0xf01079b8
f0102804:	68 ba 73 10 f0       	push   $0xf01073ba
f0102809:	68 c9 03 00 00       	push   $0x3c9
f010280e:	68 94 73 10 f0       	push   $0xf0107394
f0102813:	e8 28 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102818:	68 f4 79 10 f0       	push   $0xf01079f4
f010281d:	68 ba 73 10 f0       	push   $0xf01073ba
f0102822:	68 ca 03 00 00       	push   $0x3ca
f0102827:	68 94 73 10 f0       	push   $0xf0107394
f010282c:	e8 0f d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102831:	68 b2 75 10 f0       	push   $0xf01075b2
f0102836:	68 ba 73 10 f0       	push   $0xf01073ba
f010283b:	68 cb 03 00 00       	push   $0x3cb
f0102840:	68 94 73 10 f0       	push   $0xf0107394
f0102845:	e8 f6 d7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010284a:	68 3e 75 10 f0       	push   $0xf010753e
f010284f:	68 ba 73 10 f0       	push   $0xf01073ba
f0102854:	68 ce 03 00 00       	push   $0x3ce
f0102859:	68 94 73 10 f0       	push   $0xf0107394
f010285e:	e8 dd d7 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102863:	68 b8 79 10 f0       	push   $0xf01079b8
f0102868:	68 ba 73 10 f0       	push   $0xf01073ba
f010286d:	68 d1 03 00 00       	push   $0x3d1
f0102872:	68 94 73 10 f0       	push   $0xf0107394
f0102877:	e8 c4 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010287c:	68 f4 79 10 f0       	push   $0xf01079f4
f0102881:	68 ba 73 10 f0       	push   $0xf01073ba
f0102886:	68 d2 03 00 00       	push   $0x3d2
f010288b:	68 94 73 10 f0       	push   $0xf0107394
f0102890:	e8 ab d7 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102895:	68 b2 75 10 f0       	push   $0xf01075b2
f010289a:	68 ba 73 10 f0       	push   $0xf01073ba
f010289f:	68 d3 03 00 00       	push   $0x3d3
f01028a4:	68 94 73 10 f0       	push   $0xf0107394
f01028a9:	e8 92 d7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01028ae:	68 3e 75 10 f0       	push   $0xf010753e
f01028b3:	68 ba 73 10 f0       	push   $0xf01073ba
f01028b8:	68 d7 03 00 00       	push   $0x3d7
f01028bd:	68 94 73 10 f0       	push   $0xf0107394
f01028c2:	e8 79 d7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01028c7:	50                   	push   %eax
f01028c8:	68 04 6b 10 f0       	push   $0xf0106b04
f01028cd:	68 da 03 00 00       	push   $0x3da
f01028d2:	68 94 73 10 f0       	push   $0xf0107394
f01028d7:	e8 64 d7 ff ff       	call   f0100040 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01028dc:	68 24 7a 10 f0       	push   $0xf0107a24
f01028e1:	68 ba 73 10 f0       	push   $0xf01073ba
f01028e6:	68 db 03 00 00       	push   $0x3db
f01028eb:	68 94 73 10 f0       	push   $0xf0107394
f01028f0:	e8 4b d7 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01028f5:	68 64 7a 10 f0       	push   $0xf0107a64
f01028fa:	68 ba 73 10 f0       	push   $0xf01073ba
f01028ff:	68 de 03 00 00       	push   $0x3de
f0102904:	68 94 73 10 f0       	push   $0xf0107394
f0102909:	e8 32 d7 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010290e:	68 f4 79 10 f0       	push   $0xf01079f4
f0102913:	68 ba 73 10 f0       	push   $0xf01073ba
f0102918:	68 df 03 00 00       	push   $0x3df
f010291d:	68 94 73 10 f0       	push   $0xf0107394
f0102922:	e8 19 d7 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102927:	68 b2 75 10 f0       	push   $0xf01075b2
f010292c:	68 ba 73 10 f0       	push   $0xf01073ba
f0102931:	68 e0 03 00 00       	push   $0x3e0
f0102936:	68 94 73 10 f0       	push   $0xf0107394
f010293b:	e8 00 d7 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102940:	68 a4 7a 10 f0       	push   $0xf0107aa4
f0102945:	68 ba 73 10 f0       	push   $0xf01073ba
f010294a:	68 e1 03 00 00       	push   $0x3e1
f010294f:	68 94 73 10 f0       	push   $0xf0107394
f0102954:	e8 e7 d6 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102959:	68 c3 75 10 f0       	push   $0xf01075c3
f010295e:	68 ba 73 10 f0       	push   $0xf01073ba
f0102963:	68 e2 03 00 00       	push   $0x3e2
f0102968:	68 94 73 10 f0       	push   $0xf0107394
f010296d:	e8 ce d6 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102972:	68 b8 79 10 f0       	push   $0xf01079b8
f0102977:	68 ba 73 10 f0       	push   $0xf01073ba
f010297c:	68 e5 03 00 00       	push   $0x3e5
f0102981:	68 94 73 10 f0       	push   $0xf0107394
f0102986:	e8 b5 d6 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010298b:	68 d8 7a 10 f0       	push   $0xf0107ad8
f0102990:	68 ba 73 10 f0       	push   $0xf01073ba
f0102995:	68 e6 03 00 00       	push   $0x3e6
f010299a:	68 94 73 10 f0       	push   $0xf0107394
f010299f:	e8 9c d6 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01029a4:	68 0c 7b 10 f0       	push   $0xf0107b0c
f01029a9:	68 ba 73 10 f0       	push   $0xf01073ba
f01029ae:	68 e7 03 00 00       	push   $0x3e7
f01029b3:	68 94 73 10 f0       	push   $0xf0107394
f01029b8:	e8 83 d6 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01029bd:	68 44 7b 10 f0       	push   $0xf0107b44
f01029c2:	68 ba 73 10 f0       	push   $0xf01073ba
f01029c7:	68 ea 03 00 00       	push   $0x3ea
f01029cc:	68 94 73 10 f0       	push   $0xf0107394
f01029d1:	e8 6a d6 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01029d6:	68 7c 7b 10 f0       	push   $0xf0107b7c
f01029db:	68 ba 73 10 f0       	push   $0xf01073ba
f01029e0:	68 ed 03 00 00       	push   $0x3ed
f01029e5:	68 94 73 10 f0       	push   $0xf0107394
f01029ea:	e8 51 d6 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01029ef:	68 0c 7b 10 f0       	push   $0xf0107b0c
f01029f4:	68 ba 73 10 f0       	push   $0xf01073ba
f01029f9:	68 ee 03 00 00       	push   $0x3ee
f01029fe:	68 94 73 10 f0       	push   $0xf0107394
f0102a03:	e8 38 d6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102a08:	68 b8 7b 10 f0       	push   $0xf0107bb8
f0102a0d:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a12:	68 f1 03 00 00       	push   $0x3f1
f0102a17:	68 94 73 10 f0       	push   $0xf0107394
f0102a1c:	e8 1f d6 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102a21:	68 e4 7b 10 f0       	push   $0xf0107be4
f0102a26:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a2b:	68 f2 03 00 00       	push   $0x3f2
f0102a30:	68 94 73 10 f0       	push   $0xf0107394
f0102a35:	e8 06 d6 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 2);
f0102a3a:	68 d9 75 10 f0       	push   $0xf01075d9
f0102a3f:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a44:	68 f4 03 00 00       	push   $0x3f4
f0102a49:	68 94 73 10 f0       	push   $0xf0107394
f0102a4e:	e8 ed d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102a53:	68 ea 75 10 f0       	push   $0xf01075ea
f0102a58:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a5d:	68 f5 03 00 00       	push   $0x3f5
f0102a62:	68 94 73 10 f0       	push   $0xf0107394
f0102a67:	e8 d4 d5 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102a6c:	68 14 7c 10 f0       	push   $0xf0107c14
f0102a71:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a76:	68 f8 03 00 00       	push   $0x3f8
f0102a7b:	68 94 73 10 f0       	push   $0xf0107394
f0102a80:	e8 bb d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a85:	68 38 7c 10 f0       	push   $0xf0107c38
f0102a8a:	68 ba 73 10 f0       	push   $0xf01073ba
f0102a8f:	68 fc 03 00 00       	push   $0x3fc
f0102a94:	68 94 73 10 f0       	push   $0xf0107394
f0102a99:	e8 a2 d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102a9e:	68 e4 7b 10 f0       	push   $0xf0107be4
f0102aa3:	68 ba 73 10 f0       	push   $0xf01073ba
f0102aa8:	68 fd 03 00 00       	push   $0x3fd
f0102aad:	68 94 73 10 f0       	push   $0xf0107394
f0102ab2:	e8 89 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102ab7:	68 90 75 10 f0       	push   $0xf0107590
f0102abc:	68 ba 73 10 f0       	push   $0xf01073ba
f0102ac1:	68 fe 03 00 00       	push   $0x3fe
f0102ac6:	68 94 73 10 f0       	push   $0xf0107394
f0102acb:	e8 70 d5 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102ad0:	68 ea 75 10 f0       	push   $0xf01075ea
f0102ad5:	68 ba 73 10 f0       	push   $0xf01073ba
f0102ada:	68 ff 03 00 00       	push   $0x3ff
f0102adf:	68 94 73 10 f0       	push   $0xf0107394
f0102ae4:	e8 57 d5 ff ff       	call   f0100040 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102ae9:	68 5c 7c 10 f0       	push   $0xf0107c5c
f0102aee:	68 ba 73 10 f0       	push   $0xf01073ba
f0102af3:	68 02 04 00 00       	push   $0x402
f0102af8:	68 94 73 10 f0       	push   $0xf0107394
f0102afd:	e8 3e d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102b02:	68 fb 75 10 f0       	push   $0xf01075fb
f0102b07:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b0c:	68 03 04 00 00       	push   $0x403
f0102b11:	68 94 73 10 f0       	push   $0xf0107394
f0102b16:	e8 25 d5 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102b1b:	68 07 76 10 f0       	push   $0xf0107607
f0102b20:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b25:	68 04 04 00 00       	push   $0x404
f0102b2a:	68 94 73 10 f0       	push   $0xf0107394
f0102b2f:	e8 0c d5 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102b34:	68 38 7c 10 f0       	push   $0xf0107c38
f0102b39:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b3e:	68 08 04 00 00       	push   $0x408
f0102b43:	68 94 73 10 f0       	push   $0xf0107394
f0102b48:	e8 f3 d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102b4d:	68 94 7c 10 f0       	push   $0xf0107c94
f0102b52:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b57:	68 09 04 00 00       	push   $0x409
f0102b5c:	68 94 73 10 f0       	push   $0xf0107394
f0102b61:	e8 da d4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102b66:	68 1c 76 10 f0       	push   $0xf010761c
f0102b6b:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b70:	68 0a 04 00 00       	push   $0x40a
f0102b75:	68 94 73 10 f0       	push   $0xf0107394
f0102b7a:	e8 c1 d4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102b7f:	68 ea 75 10 f0       	push   $0xf01075ea
f0102b84:	68 ba 73 10 f0       	push   $0xf01073ba
f0102b89:	68 0b 04 00 00       	push   $0x40b
f0102b8e:	68 94 73 10 f0       	push   $0xf0107394
f0102b93:	e8 a8 d4 ff ff       	call   f0100040 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102b98:	68 bc 7c 10 f0       	push   $0xf0107cbc
f0102b9d:	68 ba 73 10 f0       	push   $0xf01073ba
f0102ba2:	68 0e 04 00 00       	push   $0x40e
f0102ba7:	68 94 73 10 f0       	push   $0xf0107394
f0102bac:	e8 8f d4 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0102bb1:	68 3e 75 10 f0       	push   $0xf010753e
f0102bb6:	68 ba 73 10 f0       	push   $0xf01073ba
f0102bbb:	68 11 04 00 00       	push   $0x411
f0102bc0:	68 94 73 10 f0       	push   $0xf0107394
f0102bc5:	e8 76 d4 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102bca:	68 60 79 10 f0       	push   $0xf0107960
f0102bcf:	68 ba 73 10 f0       	push   $0xf01073ba
f0102bd4:	68 14 04 00 00       	push   $0x414
f0102bd9:	68 94 73 10 f0       	push   $0xf0107394
f0102bde:	e8 5d d4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0102be3:	68 a1 75 10 f0       	push   $0xf01075a1
f0102be8:	68 ba 73 10 f0       	push   $0xf01073ba
f0102bed:	68 16 04 00 00       	push   $0x416
f0102bf2:	68 94 73 10 f0       	push   $0xf0107394
f0102bf7:	e8 44 d4 ff ff       	call   f0100040 <_panic>
f0102bfc:	52                   	push   %edx
f0102bfd:	68 04 6b 10 f0       	push   $0xf0106b04
f0102c02:	68 1d 04 00 00       	push   $0x41d
f0102c07:	68 94 73 10 f0       	push   $0xf0107394
f0102c0c:	e8 2f d4 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102c11:	68 2d 76 10 f0       	push   $0xf010762d
f0102c16:	68 ba 73 10 f0       	push   $0xf01073ba
f0102c1b:	68 1e 04 00 00       	push   $0x41e
f0102c20:	68 94 73 10 f0       	push   $0xf0107394
f0102c25:	e8 16 d4 ff ff       	call   f0100040 <_panic>
f0102c2a:	50                   	push   %eax
f0102c2b:	68 04 6b 10 f0       	push   $0xf0106b04
f0102c30:	6a 58                	push   $0x58
f0102c32:	68 a0 73 10 f0       	push   $0xf01073a0
f0102c37:	e8 04 d4 ff ff       	call   f0100040 <_panic>
f0102c3c:	52                   	push   %edx
f0102c3d:	68 04 6b 10 f0       	push   $0xf0106b04
f0102c42:	6a 58                	push   $0x58
f0102c44:	68 a0 73 10 f0       	push   $0xf01073a0
f0102c49:	e8 f2 d3 ff ff       	call   f0100040 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102c4e:	68 45 76 10 f0       	push   $0xf0107645
f0102c53:	68 ba 73 10 f0       	push   $0xf01073ba
f0102c58:	68 28 04 00 00       	push   $0x428
f0102c5d:	68 94 73 10 f0       	push   $0xf0107394
f0102c62:	e8 d9 d3 ff ff       	call   f0100040 <_panic>
	assert(mm1 >= MMIOBASE && mm1 + 8192 < MMIOLIM);
f0102c67:	68 e0 7c 10 f0       	push   $0xf0107ce0
f0102c6c:	68 ba 73 10 f0       	push   $0xf01073ba
f0102c71:	68 38 04 00 00       	push   $0x438
f0102c76:	68 94 73 10 f0       	push   $0xf0107394
f0102c7b:	e8 c0 d3 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8192 < MMIOLIM);
f0102c80:	68 08 7d 10 f0       	push   $0xf0107d08
f0102c85:	68 ba 73 10 f0       	push   $0xf01073ba
f0102c8a:	68 39 04 00 00       	push   $0x439
f0102c8f:	68 94 73 10 f0       	push   $0xf0107394
f0102c94:	e8 a7 d3 ff ff       	call   f0100040 <_panic>
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102c99:	68 30 7d 10 f0       	push   $0xf0107d30
f0102c9e:	68 ba 73 10 f0       	push   $0xf01073ba
f0102ca3:	68 3b 04 00 00       	push   $0x43b
f0102ca8:	68 94 73 10 f0       	push   $0xf0107394
f0102cad:	e8 8e d3 ff ff       	call   f0100040 <_panic>
	assert(mm1 + 8192 <= mm2);
f0102cb2:	68 5c 76 10 f0       	push   $0xf010765c
f0102cb7:	68 ba 73 10 f0       	push   $0xf01073ba
f0102cbc:	68 3d 04 00 00       	push   $0x43d
f0102cc1:	68 94 73 10 f0       	push   $0xf0107394
f0102cc6:	e8 75 d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102ccb:	68 58 7d 10 f0       	push   $0xf0107d58
f0102cd0:	68 ba 73 10 f0       	push   $0xf01073ba
f0102cd5:	68 3f 04 00 00       	push   $0x43f
f0102cda:	68 94 73 10 f0       	push   $0xf0107394
f0102cdf:	e8 5c d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102ce4:	68 7c 7d 10 f0       	push   $0xf0107d7c
f0102ce9:	68 ba 73 10 f0       	push   $0xf01073ba
f0102cee:	68 40 04 00 00       	push   $0x440
f0102cf3:	68 94 73 10 f0       	push   $0xf0107394
f0102cf8:	e8 43 d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102cfd:	68 ac 7d 10 f0       	push   $0xf0107dac
f0102d02:	68 ba 73 10 f0       	push   $0xf01073ba
f0102d07:	68 41 04 00 00       	push   $0x441
f0102d0c:	68 94 73 10 f0       	push   $0xf0107394
f0102d11:	e8 2a d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102d16:	68 d0 7d 10 f0       	push   $0xf0107dd0
f0102d1b:	68 ba 73 10 f0       	push   $0xf01073ba
f0102d20:	68 42 04 00 00       	push   $0x442
f0102d25:	68 94 73 10 f0       	push   $0xf0107394
f0102d2a:	e8 11 d3 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102d2f:	68 fc 7d 10 f0       	push   $0xf0107dfc
f0102d34:	68 ba 73 10 f0       	push   $0xf01073ba
f0102d39:	68 44 04 00 00       	push   $0x444
f0102d3e:	68 94 73 10 f0       	push   $0xf0107394
f0102d43:	e8 f8 d2 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102d48:	68 40 7e 10 f0       	push   $0xf0107e40
f0102d4d:	68 ba 73 10 f0       	push   $0xf01073ba
f0102d52:	68 45 04 00 00       	push   $0x445
f0102d57:	68 94 73 10 f0       	push   $0xf0107394
f0102d5c:	e8 df d2 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d61:	50                   	push   %eax
f0102d62:	68 28 6b 10 f0       	push   $0xf0106b28
f0102d67:	68 ce 00 00 00       	push   $0xce
f0102d6c:	68 94 73 10 f0       	push   $0xf0107394
f0102d71:	e8 ca d2 ff ff       	call   f0100040 <_panic>
f0102d76:	50                   	push   %eax
f0102d77:	68 28 6b 10 f0       	push   $0xf0106b28
f0102d7c:	68 d6 00 00 00       	push   $0xd6
f0102d81:	68 94 73 10 f0       	push   $0xf0107394
f0102d86:	e8 b5 d2 ff ff       	call   f0100040 <_panic>
f0102d8b:	50                   	push   %eax
f0102d8c:	68 28 6b 10 f0       	push   $0xf0106b28
f0102d91:	68 e3 00 00 00       	push   $0xe3
f0102d96:	68 94 73 10 f0       	push   $0xf0107394
f0102d9b:	e8 a0 d2 ff ff       	call   f0100040 <_panic>
f0102da0:	53                   	push   %ebx
f0102da1:	68 28 6b 10 f0       	push   $0xf0106b28
f0102da6:	68 25 01 00 00       	push   $0x125
f0102dab:	68 94 73 10 f0       	push   $0xf0107394
f0102db0:	e8 8b d2 ff ff       	call   f0100040 <_panic>
f0102db5:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102db8:	68 28 6b 10 f0       	push   $0xf0106b28
f0102dbd:	68 5d 03 00 00       	push   $0x35d
f0102dc2:	68 94 73 10 f0       	push   $0xf0107394
f0102dc7:	e8 74 d2 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102dcc:	68 74 7e 10 f0       	push   $0xf0107e74
f0102dd1:	68 ba 73 10 f0       	push   $0xf01073ba
f0102dd6:	68 5d 03 00 00       	push   $0x35d
f0102ddb:	68 94 73 10 f0       	push   $0xf0107394
f0102de0:	e8 5b d2 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102de5:	a1 44 62 21 f0       	mov    0xf0216244,%eax
f0102dea:	89 45 d0             	mov    %eax,-0x30(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102ded:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102df0:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102df5:	8d b0 00 00 40 21    	lea    0x21400000(%eax),%esi
f0102dfb:	89 da                	mov    %ebx,%edx
f0102dfd:	89 f8                	mov    %edi,%eax
f0102dff:	e8 6f e1 ff ff       	call   f0100f73 <check_va2pa>
f0102e04:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102e0b:	76 22                	jbe    f0102e2f <mem_init+0x167d>
f0102e0d:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102e10:	39 d0                	cmp    %edx,%eax
f0102e12:	75 32                	jne    f0102e46 <mem_init+0x1694>
f0102e14:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
f0102e1a:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0102e20:	75 d9                	jne    f0102dfb <mem_init+0x1649>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e22:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0102e25:	c1 e6 0c             	shl    $0xc,%esi
f0102e28:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102e2d:	eb 4b                	jmp    f0102e7a <mem_init+0x16c8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e2f:	ff 75 d0             	pushl  -0x30(%ebp)
f0102e32:	68 28 6b 10 f0       	push   $0xf0106b28
f0102e37:	68 62 03 00 00       	push   $0x362
f0102e3c:	68 94 73 10 f0       	push   $0xf0107394
f0102e41:	e8 fa d1 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102e46:	68 a8 7e 10 f0       	push   $0xf0107ea8
f0102e4b:	68 ba 73 10 f0       	push   $0xf01073ba
f0102e50:	68 62 03 00 00       	push   $0x362
f0102e55:	68 94 73 10 f0       	push   $0xf0107394
f0102e5a:	e8 e1 d1 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102e5f:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102e65:	89 f8                	mov    %edi,%eax
f0102e67:	e8 07 e1 ff ff       	call   f0100f73 <check_va2pa>
f0102e6c:	39 c3                	cmp    %eax,%ebx
f0102e6e:	0f 85 f9 00 00 00    	jne    f0102f6d <mem_init+0x17bb>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102e74:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102e7a:	39 f3                	cmp    %esi,%ebx
f0102e7c:	72 e1                	jb     f0102e5f <mem_init+0x16ad>
f0102e7e:	c7 45 d4 00 80 21 f0 	movl   $0xf0218000,-0x2c(%ebp)
f0102e85:	be 00 80 ff ef       	mov    $0xefff8000,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102e8a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e8d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102e90:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f0102e96:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102e99:	89 f3                	mov    %esi,%ebx
f0102e9b:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102e9e:	05 00 80 00 20       	add    $0x20008000,%eax
f0102ea3:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0102ea6:	89 c6                	mov    %eax,%esi
f0102ea8:	89 da                	mov    %ebx,%edx
f0102eaa:	89 f8                	mov    %edi,%eax
f0102eac:	e8 c2 e0 ff ff       	call   f0100f73 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102eb1:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f0102eb8:	0f 86 c8 00 00 00    	jbe    f0102f86 <mem_init+0x17d4>
f0102ebe:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102ec1:	39 d0                	cmp    %edx,%eax
f0102ec3:	0f 85 d4 00 00 00    	jne    f0102f9d <mem_init+0x17eb>
f0102ec9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102ecf:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f0102ed2:	75 d4                	jne    f0102ea8 <mem_init+0x16f6>
f0102ed4:	8b 75 c8             	mov    -0x38(%ebp),%esi
f0102ed7:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102edd:	89 da                	mov    %ebx,%edx
f0102edf:	89 f8                	mov    %edi,%eax
f0102ee1:	e8 8d e0 ff ff       	call   f0100f73 <check_va2pa>
f0102ee6:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102ee9:	0f 85 c7 00 00 00    	jne    f0102fb6 <mem_init+0x1804>
f0102eef:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102ef5:	39 f3                	cmp    %esi,%ebx
f0102ef7:	75 e4                	jne    f0102edd <mem_init+0x172b>
f0102ef9:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f0102eff:	81 45 cc 00 80 01 00 	addl   $0x18000,-0x34(%ebp)
f0102f06:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102f09:	81 45 d4 00 80 00 00 	addl   $0x8000,-0x2c(%ebp)
	for (n = 0; n < NCPU; n++) {
f0102f10:	3d 00 80 2d f0       	cmp    $0xf02d8000,%eax
f0102f15:	0f 85 6f ff ff ff    	jne    f0102e8a <mem_init+0x16d8>
	for (i = 0; i < NPDENTRIES; i++) {
f0102f1b:	b8 00 00 00 00       	mov    $0x0,%eax
			if (i >= PDX(KERNBASE)) {
f0102f20:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102f25:	0f 87 a4 00 00 00    	ja     f0102fcf <mem_init+0x181d>
				assert(pgdir[i] == 0);
f0102f2b:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102f2f:	0f 85 dd 00 00 00    	jne    f0103012 <mem_init+0x1860>
	for (i = 0; i < NPDENTRIES; i++) {
f0102f35:	83 c0 01             	add    $0x1,%eax
f0102f38:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102f3d:	0f 87 e8 00 00 00    	ja     f010302b <mem_init+0x1879>
		switch (i) {
f0102f43:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102f49:	83 fa 04             	cmp    $0x4,%edx
f0102f4c:	77 d2                	ja     f0102f20 <mem_init+0x176e>
			assert(pgdir[i] & PTE_P);
f0102f4e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102f52:	75 e1                	jne    f0102f35 <mem_init+0x1783>
f0102f54:	68 87 76 10 f0       	push   $0xf0107687
f0102f59:	68 ba 73 10 f0       	push   $0xf01073ba
f0102f5e:	68 7b 03 00 00       	push   $0x37b
f0102f63:	68 94 73 10 f0       	push   $0xf0107394
f0102f68:	e8 d3 d0 ff ff       	call   f0100040 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f6d:	68 dc 7e 10 f0       	push   $0xf0107edc
f0102f72:	68 ba 73 10 f0       	push   $0xf01073ba
f0102f77:	68 66 03 00 00       	push   $0x366
f0102f7c:	68 94 73 10 f0       	push   $0xf0107394
f0102f81:	e8 ba d0 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f86:	ff 75 c4             	pushl  -0x3c(%ebp)
f0102f89:	68 28 6b 10 f0       	push   $0xf0106b28
f0102f8e:	68 6e 03 00 00       	push   $0x36e
f0102f93:	68 94 73 10 f0       	push   $0xf0107394
f0102f98:	e8 a3 d0 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f0102f9d:	68 04 7f 10 f0       	push   $0xf0107f04
f0102fa2:	68 ba 73 10 f0       	push   $0xf01073ba
f0102fa7:	68 6e 03 00 00       	push   $0x36e
f0102fac:	68 94 73 10 f0       	push   $0xf0107394
f0102fb1:	e8 8a d0 ff ff       	call   f0100040 <_panic>
			assert(check_va2pa(pgdir, base + i) == ~0);
f0102fb6:	68 4c 7f 10 f0       	push   $0xf0107f4c
f0102fbb:	68 ba 73 10 f0       	push   $0xf01073ba
f0102fc0:	68 70 03 00 00       	push   $0x370
f0102fc5:	68 94 73 10 f0       	push   $0xf0107394
f0102fca:	e8 71 d0 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102fcf:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102fd2:	f6 c2 01             	test   $0x1,%dl
f0102fd5:	74 22                	je     f0102ff9 <mem_init+0x1847>
				assert(pgdir[i] & PTE_W);
f0102fd7:	f6 c2 02             	test   $0x2,%dl
f0102fda:	0f 85 55 ff ff ff    	jne    f0102f35 <mem_init+0x1783>
f0102fe0:	68 98 76 10 f0       	push   $0xf0107698
f0102fe5:	68 ba 73 10 f0       	push   $0xf01073ba
f0102fea:	68 80 03 00 00       	push   $0x380
f0102fef:	68 94 73 10 f0       	push   $0xf0107394
f0102ff4:	e8 47 d0 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ff9:	68 87 76 10 f0       	push   $0xf0107687
f0102ffe:	68 ba 73 10 f0       	push   $0xf01073ba
f0103003:	68 7f 03 00 00       	push   $0x37f
f0103008:	68 94 73 10 f0       	push   $0xf0107394
f010300d:	e8 2e d0 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] == 0);
f0103012:	68 a9 76 10 f0       	push   $0xf01076a9
f0103017:	68 ba 73 10 f0       	push   $0xf01073ba
f010301c:	68 82 03 00 00       	push   $0x382
f0103021:	68 94 73 10 f0       	push   $0xf0107394
f0103026:	e8 15 d0 ff ff       	call   f0100040 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f010302b:	83 ec 0c             	sub    $0xc,%esp
f010302e:	68 70 7f 10 f0       	push   $0xf0107f70
f0103033:	e8 33 0d 00 00       	call   f0103d6b <cprintf>
	lcr3(PADDR(kern_pgdir));
f0103038:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f010303d:	83 c4 10             	add    $0x10,%esp
f0103040:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103045:	0f 86 fe 01 00 00    	jbe    f0103249 <mem_init+0x1a97>
	return (physaddr_t)kva - KERNBASE;
f010304b:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0103050:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0103053:	b8 00 00 00 00       	mov    $0x0,%eax
f0103058:	e8 7a df ff ff       	call   f0100fd7 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f010305d:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0103060:	83 e0 f3             	and    $0xfffffff3,%eax
f0103063:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0103068:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010306b:	83 ec 0c             	sub    $0xc,%esp
f010306e:	6a 00                	push   $0x0
f0103070:	e8 59 e3 ff ff       	call   f01013ce <page_alloc>
f0103075:	89 c3                	mov    %eax,%ebx
f0103077:	83 c4 10             	add    $0x10,%esp
f010307a:	85 c0                	test   %eax,%eax
f010307c:	0f 84 dc 01 00 00    	je     f010325e <mem_init+0x1aac>
	assert((pp1 = page_alloc(0)));
f0103082:	83 ec 0c             	sub    $0xc,%esp
f0103085:	6a 00                	push   $0x0
f0103087:	e8 42 e3 ff ff       	call   f01013ce <page_alloc>
f010308c:	89 c7                	mov    %eax,%edi
f010308e:	83 c4 10             	add    $0x10,%esp
f0103091:	85 c0                	test   %eax,%eax
f0103093:	0f 84 de 01 00 00    	je     f0103277 <mem_init+0x1ac5>
	assert((pp2 = page_alloc(0)));
f0103099:	83 ec 0c             	sub    $0xc,%esp
f010309c:	6a 00                	push   $0x0
f010309e:	e8 2b e3 ff ff       	call   f01013ce <page_alloc>
f01030a3:	89 c6                	mov    %eax,%esi
f01030a5:	83 c4 10             	add    $0x10,%esp
f01030a8:	85 c0                	test   %eax,%eax
f01030aa:	0f 84 e0 01 00 00    	je     f0103290 <mem_init+0x1ade>
	page_free(pp0);
f01030b0:	83 ec 0c             	sub    $0xc,%esp
f01030b3:	53                   	push   %ebx
f01030b4:	e8 87 e3 ff ff       	call   f0101440 <page_free>
	return (pp - pages) << PGSHIFT;
f01030b9:	89 f8                	mov    %edi,%eax
f01030bb:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f01030c1:	c1 f8 03             	sar    $0x3,%eax
f01030c4:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01030c7:	89 c2                	mov    %eax,%edx
f01030c9:	c1 ea 0c             	shr    $0xc,%edx
f01030cc:	83 c4 10             	add    $0x10,%esp
f01030cf:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f01030d5:	0f 83 ce 01 00 00    	jae    f01032a9 <mem_init+0x1af7>
	memset(page2kva(pp1), 1, PGSIZE);
f01030db:	83 ec 04             	sub    $0x4,%esp
f01030de:	68 00 10 00 00       	push   $0x1000
f01030e3:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01030e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01030ea:	50                   	push   %eax
f01030eb:	e8 8d 2d 00 00       	call   f0105e7d <memset>
	return (pp - pages) << PGSHIFT;
f01030f0:	89 f0                	mov    %esi,%eax
f01030f2:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f01030f8:	c1 f8 03             	sar    $0x3,%eax
f01030fb:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01030fe:	89 c2                	mov    %eax,%edx
f0103100:	c1 ea 0c             	shr    $0xc,%edx
f0103103:	83 c4 10             	add    $0x10,%esp
f0103106:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f010310c:	0f 83 a9 01 00 00    	jae    f01032bb <mem_init+0x1b09>
	memset(page2kva(pp2), 2, PGSIZE);
f0103112:	83 ec 04             	sub    $0x4,%esp
f0103115:	68 00 10 00 00       	push   $0x1000
f010311a:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f010311c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103121:	50                   	push   %eax
f0103122:	e8 56 2d 00 00       	call   f0105e7d <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103127:	6a 02                	push   $0x2
f0103129:	68 00 10 00 00       	push   $0x1000
f010312e:	57                   	push   %edi
f010312f:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0103135:	e8 a1 e5 ff ff       	call   f01016db <page_insert>
	assert(pp1->pp_ref == 1);
f010313a:	83 c4 20             	add    $0x20,%esp
f010313d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103142:	0f 85 85 01 00 00    	jne    f01032cd <mem_init+0x1b1b>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103148:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f010314f:	01 01 01 
f0103152:	0f 85 8e 01 00 00    	jne    f01032e6 <mem_init+0x1b34>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103158:	6a 02                	push   $0x2
f010315a:	68 00 10 00 00       	push   $0x1000
f010315f:	56                   	push   %esi
f0103160:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0103166:	e8 70 e5 ff ff       	call   f01016db <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010316b:	83 c4 10             	add    $0x10,%esp
f010316e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103175:	02 02 02 
f0103178:	0f 85 81 01 00 00    	jne    f01032ff <mem_init+0x1b4d>
	assert(pp2->pp_ref == 1);
f010317e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103183:	0f 85 8f 01 00 00    	jne    f0103318 <mem_init+0x1b66>
	assert(pp1->pp_ref == 0);
f0103189:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010318e:	0f 85 9d 01 00 00    	jne    f0103331 <mem_init+0x1b7f>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103194:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010319b:	03 03 03 
	return (pp - pages) << PGSHIFT;
f010319e:	89 f0                	mov    %esi,%eax
f01031a0:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f01031a6:	c1 f8 03             	sar    $0x3,%eax
f01031a9:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01031ac:	89 c2                	mov    %eax,%edx
f01031ae:	c1 ea 0c             	shr    $0xc,%edx
f01031b1:	3b 15 88 6e 21 f0    	cmp    0xf0216e88,%edx
f01031b7:	0f 83 8d 01 00 00    	jae    f010334a <mem_init+0x1b98>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01031bd:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01031c4:	03 03 03 
f01031c7:	0f 85 8f 01 00 00    	jne    f010335c <mem_init+0x1baa>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01031cd:	83 ec 08             	sub    $0x8,%esp
f01031d0:	68 00 10 00 00       	push   $0x1000
f01031d5:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f01031db:	e8 ae e4 ff ff       	call   f010168e <page_remove>
	assert(pp2->pp_ref == 0);
f01031e0:	83 c4 10             	add    $0x10,%esp
f01031e3:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01031e8:	0f 85 87 01 00 00    	jne    f0103375 <mem_init+0x1bc3>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01031ee:	8b 0d 8c 6e 21 f0    	mov    0xf0216e8c,%ecx
f01031f4:	8b 11                	mov    (%ecx),%edx
f01031f6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f01031fc:	89 d8                	mov    %ebx,%eax
f01031fe:	2b 05 90 6e 21 f0    	sub    0xf0216e90,%eax
f0103204:	c1 f8 03             	sar    $0x3,%eax
f0103207:	c1 e0 0c             	shl    $0xc,%eax
f010320a:	39 c2                	cmp    %eax,%edx
f010320c:	0f 85 7c 01 00 00    	jne    f010338e <mem_init+0x1bdc>
	kern_pgdir[0] = 0;
f0103212:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0103218:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010321d:	0f 85 84 01 00 00    	jne    f01033a7 <mem_init+0x1bf5>
	pp0->pp_ref = 0;
f0103223:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0103229:	83 ec 0c             	sub    $0xc,%esp
f010322c:	53                   	push   %ebx
f010322d:	e8 0e e2 ff ff       	call   f0101440 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103232:	c7 04 24 04 80 10 f0 	movl   $0xf0108004,(%esp)
f0103239:	e8 2d 0b 00 00       	call   f0103d6b <cprintf>
}
f010323e:	83 c4 10             	add    $0x10,%esp
f0103241:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103244:	5b                   	pop    %ebx
f0103245:	5e                   	pop    %esi
f0103246:	5f                   	pop    %edi
f0103247:	5d                   	pop    %ebp
f0103248:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103249:	50                   	push   %eax
f010324a:	68 28 6b 10 f0       	push   $0xf0106b28
f010324f:	68 fd 00 00 00       	push   $0xfd
f0103254:	68 94 73 10 f0       	push   $0xf0107394
f0103259:	e8 e2 cd ff ff       	call   f0100040 <_panic>
	assert((pp0 = page_alloc(0)));
f010325e:	68 93 74 10 f0       	push   $0xf0107493
f0103263:	68 ba 73 10 f0       	push   $0xf01073ba
f0103268:	68 5a 04 00 00       	push   $0x45a
f010326d:	68 94 73 10 f0       	push   $0xf0107394
f0103272:	e8 c9 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0103277:	68 a9 74 10 f0       	push   $0xf01074a9
f010327c:	68 ba 73 10 f0       	push   $0xf01073ba
f0103281:	68 5b 04 00 00       	push   $0x45b
f0103286:	68 94 73 10 f0       	push   $0xf0107394
f010328b:	e8 b0 cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103290:	68 bf 74 10 f0       	push   $0xf01074bf
f0103295:	68 ba 73 10 f0       	push   $0xf01073ba
f010329a:	68 5c 04 00 00       	push   $0x45c
f010329f:	68 94 73 10 f0       	push   $0xf0107394
f01032a4:	e8 97 cd ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01032a9:	50                   	push   %eax
f01032aa:	68 04 6b 10 f0       	push   $0xf0106b04
f01032af:	6a 58                	push   $0x58
f01032b1:	68 a0 73 10 f0       	push   $0xf01073a0
f01032b6:	e8 85 cd ff ff       	call   f0100040 <_panic>
f01032bb:	50                   	push   %eax
f01032bc:	68 04 6b 10 f0       	push   $0xf0106b04
f01032c1:	6a 58                	push   $0x58
f01032c3:	68 a0 73 10 f0       	push   $0xf01073a0
f01032c8:	e8 73 cd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01032cd:	68 90 75 10 f0       	push   $0xf0107590
f01032d2:	68 ba 73 10 f0       	push   $0xf01073ba
f01032d7:	68 61 04 00 00       	push   $0x461
f01032dc:	68 94 73 10 f0       	push   $0xf0107394
f01032e1:	e8 5a cd ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01032e6:	68 90 7f 10 f0       	push   $0xf0107f90
f01032eb:	68 ba 73 10 f0       	push   $0xf01073ba
f01032f0:	68 62 04 00 00       	push   $0x462
f01032f5:	68 94 73 10 f0       	push   $0xf0107394
f01032fa:	e8 41 cd ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f01032ff:	68 b4 7f 10 f0       	push   $0xf0107fb4
f0103304:	68 ba 73 10 f0       	push   $0xf01073ba
f0103309:	68 64 04 00 00       	push   $0x464
f010330e:	68 94 73 10 f0       	push   $0xf0107394
f0103313:	e8 28 cd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0103318:	68 b2 75 10 f0       	push   $0xf01075b2
f010331d:	68 ba 73 10 f0       	push   $0xf01073ba
f0103322:	68 65 04 00 00       	push   $0x465
f0103327:	68 94 73 10 f0       	push   $0xf0107394
f010332c:	e8 0f cd ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103331:	68 1c 76 10 f0       	push   $0xf010761c
f0103336:	68 ba 73 10 f0       	push   $0xf01073ba
f010333b:	68 66 04 00 00       	push   $0x466
f0103340:	68 94 73 10 f0       	push   $0xf0107394
f0103345:	e8 f6 cc ff ff       	call   f0100040 <_panic>
f010334a:	50                   	push   %eax
f010334b:	68 04 6b 10 f0       	push   $0xf0106b04
f0103350:	6a 58                	push   $0x58
f0103352:	68 a0 73 10 f0       	push   $0xf01073a0
f0103357:	e8 e4 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f010335c:	68 d8 7f 10 f0       	push   $0xf0107fd8
f0103361:	68 ba 73 10 f0       	push   $0xf01073ba
f0103366:	68 68 04 00 00       	push   $0x468
f010336b:	68 94 73 10 f0       	push   $0xf0107394
f0103370:	e8 cb cc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0103375:	68 ea 75 10 f0       	push   $0xf01075ea
f010337a:	68 ba 73 10 f0       	push   $0xf01073ba
f010337f:	68 6a 04 00 00       	push   $0x46a
f0103384:	68 94 73 10 f0       	push   $0xf0107394
f0103389:	e8 b2 cc ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010338e:	68 60 79 10 f0       	push   $0xf0107960
f0103393:	68 ba 73 10 f0       	push   $0xf01073ba
f0103398:	68 6d 04 00 00       	push   $0x46d
f010339d:	68 94 73 10 f0       	push   $0xf0107394
f01033a2:	e8 99 cc ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f01033a7:	68 a1 75 10 f0       	push   $0xf01075a1
f01033ac:	68 ba 73 10 f0       	push   $0xf01073ba
f01033b1:	68 6f 04 00 00       	push   $0x46f
f01033b6:	68 94 73 10 f0       	push   $0xf0107394
f01033bb:	e8 80 cc ff ff       	call   f0100040 <_panic>

f01033c0 <user_mem_check>:
{
f01033c0:	55                   	push   %ebp
f01033c1:	89 e5                	mov    %esp,%ebp
f01033c3:	57                   	push   %edi
f01033c4:	56                   	push   %esi
f01033c5:	53                   	push   %ebx
f01033c6:	83 ec 0c             	sub    $0xc,%esp
	uintptr_t beg = ROUNDDOWN((uint32_t)(va), PGSIZE);
f01033c9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01033cc:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t fin = ROUNDUP((uint32_t)(va + len), PGSIZE);
f01033d2:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01033d5:	03 7d 10             	add    0x10(%ebp),%edi
f01033d8:	81 c7 ff 0f 00 00    	add    $0xfff,%edi
f01033de:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
		if (p == NULL || (*p & (perm | PTE_P)) != (perm | PTE_P) || beg >= ULIM){
f01033e4:	8b 75 14             	mov    0x14(%ebp),%esi
f01033e7:	83 ce 01             	or     $0x1,%esi
	for (; beg < fin; beg += PGSIZE){
f01033ea:	39 fb                	cmp    %edi,%ebx
f01033ec:	73 4a                	jae    f0103438 <user_mem_check+0x78>
		pte_t * p = pgdir_walk(env -> env_pgdir, (void *)beg, 0);
f01033ee:	83 ec 04             	sub    $0x4,%esp
f01033f1:	6a 00                	push   $0x0
f01033f3:	53                   	push   %ebx
f01033f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01033f7:	ff 70 60             	pushl  0x60(%eax)
f01033fa:	e8 bc e0 ff ff       	call   f01014bb <pgdir_walk>
		if (p == NULL || (*p & (perm | PTE_P)) != (perm | PTE_P) || beg >= ULIM){
f01033ff:	83 c4 10             	add    $0x10,%esp
f0103402:	85 c0                	test   %eax,%eax
f0103404:	74 18                	je     f010341e <user_mem_check+0x5e>
f0103406:	89 f2                	mov    %esi,%edx
f0103408:	23 10                	and    (%eax),%edx
f010340a:	39 f2                	cmp    %esi,%edx
f010340c:	75 10                	jne    f010341e <user_mem_check+0x5e>
f010340e:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103414:	77 08                	ja     f010341e <user_mem_check+0x5e>
	for (; beg < fin; beg += PGSIZE){
f0103416:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010341c:	eb cc                	jmp    f01033ea <user_mem_check+0x2a>
			user_mem_check_addr = (beg < (uintptr_t)va ? (uintptr_t)va : beg);
f010341e:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0103421:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f0103425:	89 1d 3c 62 21 f0    	mov    %ebx,0xf021623c
			return -E_FAULT;
f010342b:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f0103430:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103433:	5b                   	pop    %ebx
f0103434:	5e                   	pop    %esi
f0103435:	5f                   	pop    %edi
f0103436:	5d                   	pop    %ebp
f0103437:	c3                   	ret    
	return 0;
f0103438:	b8 00 00 00 00       	mov    $0x0,%eax
f010343d:	eb f1                	jmp    f0103430 <user_mem_check+0x70>

f010343f <user_mem_assert>:
{
f010343f:	55                   	push   %ebp
f0103440:	89 e5                	mov    %esp,%ebp
f0103442:	53                   	push   %ebx
f0103443:	83 ec 04             	sub    $0x4,%esp
f0103446:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103449:	8b 45 14             	mov    0x14(%ebp),%eax
f010344c:	83 c8 04             	or     $0x4,%eax
f010344f:	50                   	push   %eax
f0103450:	ff 75 10             	pushl  0x10(%ebp)
f0103453:	ff 75 0c             	pushl  0xc(%ebp)
f0103456:	53                   	push   %ebx
f0103457:	e8 64 ff ff ff       	call   f01033c0 <user_mem_check>
f010345c:	83 c4 10             	add    $0x10,%esp
f010345f:	85 c0                	test   %eax,%eax
f0103461:	78 05                	js     f0103468 <user_mem_assert+0x29>
}
f0103463:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103466:	c9                   	leave  
f0103467:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103468:	83 ec 04             	sub    $0x4,%esp
f010346b:	ff 35 3c 62 21 f0    	pushl  0xf021623c
f0103471:	ff 73 48             	pushl  0x48(%ebx)
f0103474:	68 30 80 10 f0       	push   $0xf0108030
f0103479:	e8 ed 08 00 00       	call   f0103d6b <cprintf>
		env_destroy(env);	// may not return
f010347e:	89 1c 24             	mov    %ebx,(%esp)
f0103481:	e8 e9 05 00 00       	call   f0103a6f <env_destroy>
f0103486:	83 c4 10             	add    $0x10,%esp
}
f0103489:	eb d8                	jmp    f0103463 <user_mem_assert+0x24>

f010348b <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010348b:	55                   	push   %ebp
f010348c:	89 e5                	mov    %esp,%ebp
f010348e:	57                   	push   %edi
f010348f:	56                   	push   %esi
f0103490:	53                   	push   %ebx
f0103491:	83 ec 0c             	sub    $0xc,%esp
f0103494:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* beg = (void*)ROUNDDOWN((uint32_t)va, PGSIZE);
f0103496:	89 d3                	mov    %edx,%ebx
f0103498:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* fin = (void*)ROUNDUP((uint32_t)(va + len), PGSIZE);
f010349e:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01034a5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	for (;beg < fin;beg += PGSIZE){
f01034ab:	39 f3                	cmp    %esi,%ebx
f01034ad:	73 5a                	jae    f0103509 <region_alloc+0x7e>
		struct PageInfo* page;
		if (!(page = page_alloc(ALLOC_ZERO)))
f01034af:	83 ec 0c             	sub    $0xc,%esp
f01034b2:	6a 01                	push   $0x1
f01034b4:	e8 15 df ff ff       	call   f01013ce <page_alloc>
f01034b9:	83 c4 10             	add    $0x10,%esp
f01034bc:	85 c0                	test   %eax,%eax
f01034be:	74 1b                	je     f01034db <region_alloc+0x50>
			panic("allocation failed");
		if (page_insert(e -> env_pgdir, page, (void*)beg, PTE_U | PTE_W))
f01034c0:	6a 06                	push   $0x6
f01034c2:	53                   	push   %ebx
f01034c3:	50                   	push   %eax
f01034c4:	ff 77 60             	pushl  0x60(%edi)
f01034c7:	e8 0f e2 ff ff       	call   f01016db <page_insert>
f01034cc:	83 c4 10             	add    $0x10,%esp
f01034cf:	85 c0                	test   %eax,%eax
f01034d1:	75 1f                	jne    f01034f2 <region_alloc+0x67>
	for (;beg < fin;beg += PGSIZE){
f01034d3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01034d9:	eb d0                	jmp    f01034ab <region_alloc+0x20>
			panic("allocation failed");
f01034db:	83 ec 04             	sub    $0x4,%esp
f01034de:	68 65 80 10 f0       	push   $0xf0108065
f01034e3:	68 2a 01 00 00       	push   $0x12a
f01034e8:	68 77 80 10 f0       	push   $0xf0108077
f01034ed:	e8 4e cb ff ff       	call   f0100040 <_panic>
			panic("mapping failed");
f01034f2:	83 ec 04             	sub    $0x4,%esp
f01034f5:	68 82 80 10 f0       	push   $0xf0108082
f01034fa:	68 2c 01 00 00       	push   $0x12c
f01034ff:	68 77 80 10 f0       	push   $0xf0108077
f0103504:	e8 37 cb ff ff       	call   f0100040 <_panic>
	}
}
f0103509:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010350c:	5b                   	pop    %ebx
f010350d:	5e                   	pop    %esi
f010350e:	5f                   	pop    %edi
f010350f:	5d                   	pop    %ebp
f0103510:	c3                   	ret    

f0103511 <envid2env>:
{
f0103511:	55                   	push   %ebp
f0103512:	89 e5                	mov    %esp,%ebp
f0103514:	56                   	push   %esi
f0103515:	53                   	push   %ebx
f0103516:	8b 45 08             	mov    0x8(%ebp),%eax
f0103519:	8b 55 10             	mov    0x10(%ebp),%edx
	if (envid == 0) {
f010351c:	85 c0                	test   %eax,%eax
f010351e:	74 2e                	je     f010354e <envid2env+0x3d>
	e = &envs[ENVX(envid)];
f0103520:	89 c3                	mov    %eax,%ebx
f0103522:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103528:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f010352b:	03 1d 44 62 21 f0    	add    0xf0216244,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103531:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103535:	74 31                	je     f0103568 <envid2env+0x57>
f0103537:	39 43 48             	cmp    %eax,0x48(%ebx)
f010353a:	75 2c                	jne    f0103568 <envid2env+0x57>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010353c:	84 d2                	test   %dl,%dl
f010353e:	75 38                	jne    f0103578 <envid2env+0x67>
	*env_store = e;
f0103540:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103543:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103545:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010354a:	5b                   	pop    %ebx
f010354b:	5e                   	pop    %esi
f010354c:	5d                   	pop    %ebp
f010354d:	c3                   	ret    
		*env_store = curenv;
f010354e:	e8 50 2f 00 00       	call   f01064a3 <cpunum>
f0103553:	6b c0 74             	imul   $0x74,%eax,%eax
f0103556:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f010355c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010355f:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103561:	b8 00 00 00 00       	mov    $0x0,%eax
f0103566:	eb e2                	jmp    f010354a <envid2env+0x39>
		*env_store = 0;
f0103568:	8b 45 0c             	mov    0xc(%ebp),%eax
f010356b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103571:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103576:	eb d2                	jmp    f010354a <envid2env+0x39>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103578:	e8 26 2f 00 00       	call   f01064a3 <cpunum>
f010357d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103580:	39 98 28 70 21 f0    	cmp    %ebx,-0xfde8fd8(%eax)
f0103586:	74 b8                	je     f0103540 <envid2env+0x2f>
f0103588:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010358b:	e8 13 2f 00 00       	call   f01064a3 <cpunum>
f0103590:	6b c0 74             	imul   $0x74,%eax,%eax
f0103593:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103599:	3b 70 48             	cmp    0x48(%eax),%esi
f010359c:	74 a2                	je     f0103540 <envid2env+0x2f>
		*env_store = 0;
f010359e:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035a1:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01035a7:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01035ac:	eb 9c                	jmp    f010354a <envid2env+0x39>

f01035ae <env_init_percpu>:
{
f01035ae:	55                   	push   %ebp
f01035af:	89 e5                	mov    %esp,%ebp
	asm volatile("lgdt (%0)" : : "r" (p));
f01035b1:	b8 20 33 12 f0       	mov    $0xf0123320,%eax
f01035b6:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01035b9:	b8 23 00 00 00       	mov    $0x23,%eax
f01035be:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01035c0:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01035c2:	b8 10 00 00 00       	mov    $0x10,%eax
f01035c7:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01035c9:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01035cb:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01035cd:	ea d4 35 10 f0 08 00 	ljmp   $0x8,$0xf01035d4
	asm volatile("lldt %0" : : "r" (sel));
f01035d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01035d9:	0f 00 d0             	lldt   %ax
}
f01035dc:	5d                   	pop    %ebp
f01035dd:	c3                   	ret    

f01035de <env_init>:
{
f01035de:	55                   	push   %ebp
f01035df:	89 e5                	mov    %esp,%ebp
f01035e1:	56                   	push   %esi
f01035e2:	53                   	push   %ebx
		envs[i].env_link = env_free_list;
f01035e3:	8b 35 44 62 21 f0    	mov    0xf0216244,%esi
f01035e9:	8d 86 84 ef 01 00    	lea    0x1ef84(%esi),%eax
f01035ef:	8d 5e 84             	lea    -0x7c(%esi),%ebx
f01035f2:	ba 00 00 00 00       	mov    $0x0,%edx
f01035f7:	89 c1                	mov    %eax,%ecx
f01035f9:	89 50 44             	mov    %edx,0x44(%eax)
		envs[i].env_status = ENV_FREE;
f01035fc:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f0103603:	83 e8 7c             	sub    $0x7c,%eax
		env_free_list = &envs[i];
f0103606:	89 ca                	mov    %ecx,%edx
	for (int i = NENV - 1; i >= 0; i --){
f0103608:	39 d8                	cmp    %ebx,%eax
f010360a:	75 eb                	jne    f01035f7 <env_init+0x19>
f010360c:	89 35 48 62 21 f0    	mov    %esi,0xf0216248
	env_init_percpu();
f0103612:	e8 97 ff ff ff       	call   f01035ae <env_init_percpu>
}
f0103617:	5b                   	pop    %ebx
f0103618:	5e                   	pop    %esi
f0103619:	5d                   	pop    %ebp
f010361a:	c3                   	ret    

f010361b <env_alloc>:
{
f010361b:	55                   	push   %ebp
f010361c:	89 e5                	mov    %esp,%ebp
f010361e:	53                   	push   %ebx
f010361f:	83 ec 04             	sub    $0x4,%esp
	if (!(e = env_free_list))
f0103622:	8b 1d 48 62 21 f0    	mov    0xf0216248,%ebx
f0103628:	85 db                	test   %ebx,%ebx
f010362a:	0f 84 3d 01 00 00    	je     f010376d <env_alloc+0x152>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103630:	83 ec 0c             	sub    $0xc,%esp
f0103633:	6a 01                	push   $0x1
f0103635:	e8 94 dd ff ff       	call   f01013ce <page_alloc>
f010363a:	83 c4 10             	add    $0x10,%esp
f010363d:	85 c0                	test   %eax,%eax
f010363f:	0f 84 2f 01 00 00    	je     f0103774 <env_alloc+0x159>
	return (pp - pages) << PGSHIFT;
f0103645:	89 c2                	mov    %eax,%edx
f0103647:	2b 15 90 6e 21 f0    	sub    0xf0216e90,%edx
f010364d:	c1 fa 03             	sar    $0x3,%edx
f0103650:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f0103653:	89 d1                	mov    %edx,%ecx
f0103655:	c1 e9 0c             	shr    $0xc,%ecx
f0103658:	3b 0d 88 6e 21 f0    	cmp    0xf0216e88,%ecx
f010365e:	0f 83 e2 00 00 00    	jae    f0103746 <env_alloc+0x12b>
	return (void *)(pa + KERNBASE);
f0103664:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f010366a:	89 53 60             	mov    %edx,0x60(%ebx)
	p -> pp_ref ++;
f010366d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	memcpy(e -> env_pgdir, kern_pgdir, PGSIZE); 
f0103672:	83 ec 04             	sub    $0x4,%esp
f0103675:	68 00 10 00 00       	push   $0x1000
f010367a:	ff 35 8c 6e 21 f0    	pushl  0xf0216e8c
f0103680:	ff 73 60             	pushl  0x60(%ebx)
f0103683:	e8 aa 28 00 00       	call   f0105f32 <memcpy>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103688:	8b 43 60             	mov    0x60(%ebx),%eax
	if ((uint32_t)kva < KERNBASE)
f010368b:	83 c4 10             	add    $0x10,%esp
f010368e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103693:	0f 86 bf 00 00 00    	jbe    f0103758 <env_alloc+0x13d>
	return (physaddr_t)kva - KERNBASE;
f0103699:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010369f:	83 ca 05             	or     $0x5,%edx
f01036a2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01036a8:	8b 43 48             	mov    0x48(%ebx),%eax
f01036ab:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01036b0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01036b5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01036ba:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01036bd:	89 da                	mov    %ebx,%edx
f01036bf:	2b 15 44 62 21 f0    	sub    0xf0216244,%edx
f01036c5:	c1 fa 02             	sar    $0x2,%edx
f01036c8:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01036ce:	09 d0                	or     %edx,%eax
f01036d0:	89 43 48             	mov    %eax,0x48(%ebx)
	e->env_parent_id = parent_id;
f01036d3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036d6:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01036d9:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01036e0:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01036e7:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01036ee:	83 ec 04             	sub    $0x4,%esp
f01036f1:	6a 44                	push   $0x44
f01036f3:	6a 00                	push   $0x0
f01036f5:	53                   	push   %ebx
f01036f6:	e8 82 27 00 00       	call   f0105e7d <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f01036fb:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103701:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103707:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010370d:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103714:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	e->env_tf.tf_eflags |= FL_IF;
f010371a:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)
	e->env_pgfault_upcall = 0;
f0103721:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)
	e->env_ipc_recving = 0;
f0103728:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	env_free_list = e->env_link;
f010372c:	8b 43 44             	mov    0x44(%ebx),%eax
f010372f:	a3 48 62 21 f0       	mov    %eax,0xf0216248
	*newenv_store = e;
f0103734:	8b 45 08             	mov    0x8(%ebp),%eax
f0103737:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103739:	83 c4 10             	add    $0x10,%esp
f010373c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103741:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103744:	c9                   	leave  
f0103745:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103746:	52                   	push   %edx
f0103747:	68 04 6b 10 f0       	push   $0xf0106b04
f010374c:	6a 58                	push   $0x58
f010374e:	68 a0 73 10 f0       	push   $0xf01073a0
f0103753:	e8 e8 c8 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103758:	50                   	push   %eax
f0103759:	68 28 6b 10 f0       	push   $0xf0106b28
f010375e:	68 c6 00 00 00       	push   $0xc6
f0103763:	68 77 80 10 f0       	push   $0xf0108077
f0103768:	e8 d3 c8 ff ff       	call   f0100040 <_panic>
		return -E_NO_FREE_ENV;
f010376d:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103772:	eb cd                	jmp    f0103741 <env_alloc+0x126>
		return -E_NO_MEM;
f0103774:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0103779:	eb c6                	jmp    f0103741 <env_alloc+0x126>

f010377b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010377b:	55                   	push   %ebp
f010377c:	89 e5                	mov    %esp,%ebp
f010377e:	57                   	push   %edi
f010377f:	56                   	push   %esi
f0103780:	53                   	push   %ebx
f0103781:	83 ec 34             	sub    $0x34,%esp
f0103784:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.

	struct Env* e;
	int result = env_alloc(&e, 0);
f0103787:	6a 00                	push   $0x0
f0103789:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010378c:	50                   	push   %eax
f010378d:	e8 89 fe ff ff       	call   f010361b <env_alloc>
f0103792:	89 c6                	mov    %eax,%esi
	if (result != 0)
f0103794:	83 c4 10             	add    $0x10,%esp
f0103797:	85 c0                	test   %eax,%eax
f0103799:	75 2a                	jne    f01037c5 <env_create+0x4a>
		panic("error while creating environment: %e", result);
	load_icode(e, binary);
f010379b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010379e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (ElfHeader -> e_magic != ELF_MAGIC)
f01037a1:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01037a7:	75 31                	jne    f01037da <env_create+0x5f>
	lcr3(PADDR(e -> env_pgdir));
f01037a9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037ac:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01037af:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01037b4:	76 3b                	jbe    f01037f1 <env_create+0x76>
	return (physaddr_t)kva - KERNBASE;
f01037b6:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037bb:	0f 22 d8             	mov    %eax,%cr3
f01037be:	89 fb                	mov    %edi,%ebx
f01037c0:	03 5f 1c             	add    0x1c(%edi),%ebx
f01037c3:	eb 47                	jmp    f010380c <env_create+0x91>
		panic("error while creating environment: %e", result);
f01037c5:	50                   	push   %eax
f01037c6:	68 a0 80 10 f0       	push   $0xf01080a0
f01037cb:	68 8e 01 00 00       	push   $0x18e
f01037d0:	68 77 80 10 f0       	push   $0xf0108077
f01037d5:	e8 66 c8 ff ff       	call   f0100040 <_panic>
		panic("Wrong magic number in elf header");
f01037da:	83 ec 04             	sub    $0x4,%esp
f01037dd:	68 c8 80 10 f0       	push   $0xf01080c8
f01037e2:	68 69 01 00 00       	push   $0x169
f01037e7:	68 77 80 10 f0       	push   $0xf0108077
f01037ec:	e8 4f c8 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01037f1:	50                   	push   %eax
f01037f2:	68 28 6b 10 f0       	push   $0xf0106b28
f01037f7:	68 6b 01 00 00       	push   $0x16b
f01037fc:	68 77 80 10 f0       	push   $0xf0108077
f0103801:	e8 3a c8 ff ff       	call   f0100040 <_panic>
	for (int i = 0; i < ElfHeader -> e_phnum; i++)
f0103806:	83 c6 01             	add    $0x1,%esi
f0103809:	83 c3 20             	add    $0x20,%ebx
f010380c:	0f b7 47 2c          	movzwl 0x2c(%edi),%eax
f0103810:	39 c6                	cmp    %eax,%esi
f0103812:	7d 3c                	jge    f0103850 <env_create+0xd5>
		if (ProgHeader[i].p_type == ELF_PROG_LOAD){
f0103814:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103817:	75 ed                	jne    f0103806 <env_create+0x8b>
			region_alloc(e, (void*)ph -> p_va, ph ->p_memsz);
f0103819:	8b 4b 14             	mov    0x14(%ebx),%ecx
f010381c:	8b 53 08             	mov    0x8(%ebx),%edx
f010381f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103822:	e8 64 fc ff ff       	call   f010348b <region_alloc>
			memset((void*) ph -> p_va, 0, ph -> p_memsz);
f0103827:	83 ec 04             	sub    $0x4,%esp
f010382a:	ff 73 14             	pushl  0x14(%ebx)
f010382d:	6a 00                	push   $0x0
f010382f:	ff 73 08             	pushl  0x8(%ebx)
f0103832:	e8 46 26 00 00       	call   f0105e7d <memset>
			memcpy((void*) ph -> p_va, (void*) binary + ph -> p_offset, ph -> p_filesz);
f0103837:	83 c4 0c             	add    $0xc,%esp
f010383a:	ff 73 10             	pushl  0x10(%ebx)
f010383d:	89 f8                	mov    %edi,%eax
f010383f:	03 43 04             	add    0x4(%ebx),%eax
f0103842:	50                   	push   %eax
f0103843:	ff 73 08             	pushl  0x8(%ebx)
f0103846:	e8 e7 26 00 00       	call   f0105f32 <memcpy>
f010384b:	83 c4 10             	add    $0x10,%esp
f010384e:	eb b6                	jmp    f0103806 <env_create+0x8b>
	lcr3(PADDR(kern_pgdir));
f0103850:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0103855:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010385a:	76 38                	jbe    f0103894 <env_create+0x119>
	return (physaddr_t)kva - KERNBASE;
f010385c:	05 00 00 00 10       	add    $0x10000000,%eax
f0103861:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = ElfHeader -> e_entry;
f0103864:	8b 47 18             	mov    0x18(%edi),%eax
f0103867:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010386a:	89 46 30             	mov    %eax,0x30(%esi)
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f010386d:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103872:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103877:	89 f0                	mov    %esi,%eax
f0103879:	e8 0d fc ff ff       	call   f010348b <region_alloc>
	e -> env_type = type;
f010387e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103881:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103884:	89 48 50             	mov    %ecx,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.

	if (type == ENV_TYPE_FS)
f0103887:	83 f9 01             	cmp    $0x1,%ecx
f010388a:	74 1d                	je     f01038a9 <env_create+0x12e>
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
}
f010388c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010388f:	5b                   	pop    %ebx
f0103890:	5e                   	pop    %esi
f0103891:	5f                   	pop    %edi
f0103892:	5d                   	pop    %ebp
f0103893:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103894:	50                   	push   %eax
f0103895:	68 28 6b 10 f0       	push   $0xf0106b28
f010389a:	68 75 01 00 00       	push   $0x175
f010389f:	68 77 80 10 f0       	push   $0xf0108077
f01038a4:	e8 97 c7 ff ff       	call   f0100040 <_panic>
		e->env_tf.tf_eflags |= FL_IOPL_MASK;
f01038a9:	81 48 38 00 30 00 00 	orl    $0x3000,0x38(%eax)
}
f01038b0:	eb da                	jmp    f010388c <env_create+0x111>

f01038b2 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01038b2:	55                   	push   %ebp
f01038b3:	89 e5                	mov    %esp,%ebp
f01038b5:	57                   	push   %edi
f01038b6:	56                   	push   %esi
f01038b7:	53                   	push   %ebx
f01038b8:	83 ec 1c             	sub    $0x1c,%esp
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01038bb:	e8 e3 2b 00 00       	call   f01064a3 <cpunum>
f01038c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01038c3:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01038ca:	8b 55 08             	mov    0x8(%ebp),%edx
f01038cd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01038d0:	39 90 28 70 21 f0    	cmp    %edx,-0xfde8fd8(%eax)
f01038d6:	0f 85 b2 00 00 00    	jne    f010398e <env_free+0xdc>
		lcr3(PADDR(kern_pgdir));
f01038dc:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f01038e1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01038e6:	76 17                	jbe    f01038ff <env_free+0x4d>
	return (physaddr_t)kva - KERNBASE;
f01038e8:	05 00 00 00 10       	add    $0x10000000,%eax
f01038ed:	0f 22 d8             	mov    %eax,%cr3
f01038f0:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01038f7:	8b 7d 08             	mov    0x8(%ebp),%edi
f01038fa:	e9 8f 00 00 00       	jmp    f010398e <env_free+0xdc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038ff:	50                   	push   %eax
f0103900:	68 28 6b 10 f0       	push   $0xf0106b28
f0103905:	68 a7 01 00 00       	push   $0x1a7
f010390a:	68 77 80 10 f0       	push   $0xf0108077
f010390f:	e8 2c c7 ff ff       	call   f0100040 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103914:	50                   	push   %eax
f0103915:	68 04 6b 10 f0       	push   $0xf0106b04
f010391a:	68 b6 01 00 00       	push   $0x1b6
f010391f:	68 77 80 10 f0       	push   $0xf0108077
f0103924:	e8 17 c7 ff ff       	call   f0100040 <_panic>
f0103929:	83 c3 04             	add    $0x4,%ebx
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010392c:	39 de                	cmp    %ebx,%esi
f010392e:	74 21                	je     f0103951 <env_free+0x9f>
			if (pt[pteno] & PTE_P)
f0103930:	f6 03 01             	testb  $0x1,(%ebx)
f0103933:	74 f4                	je     f0103929 <env_free+0x77>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103935:	83 ec 08             	sub    $0x8,%esp
f0103938:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010393b:	01 d8                	add    %ebx,%eax
f010393d:	c1 e0 0a             	shl    $0xa,%eax
f0103940:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103943:	50                   	push   %eax
f0103944:	ff 77 60             	pushl  0x60(%edi)
f0103947:	e8 42 dd ff ff       	call   f010168e <page_remove>
f010394c:	83 c4 10             	add    $0x10,%esp
f010394f:	eb d8                	jmp    f0103929 <env_free+0x77>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103951:	8b 47 60             	mov    0x60(%edi),%eax
f0103954:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103957:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f010395e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103961:	3b 05 88 6e 21 f0    	cmp    0xf0216e88,%eax
f0103967:	73 6a                	jae    f01039d3 <env_free+0x121>
		page_decref(pa2page(pa));
f0103969:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010396c:	a1 90 6e 21 f0       	mov    0xf0216e90,%eax
f0103971:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103974:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103977:	50                   	push   %eax
f0103978:	e8 15 db ff ff       	call   f0101492 <page_decref>
f010397d:	83 c4 10             	add    $0x10,%esp
f0103980:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f0103984:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103987:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f010398c:	74 59                	je     f01039e7 <env_free+0x135>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f010398e:	8b 47 60             	mov    0x60(%edi),%eax
f0103991:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103994:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103997:	a8 01                	test   $0x1,%al
f0103999:	74 e5                	je     f0103980 <env_free+0xce>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010399b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f01039a0:	89 c2                	mov    %eax,%edx
f01039a2:	c1 ea 0c             	shr    $0xc,%edx
f01039a5:	89 55 d8             	mov    %edx,-0x28(%ebp)
f01039a8:	39 15 88 6e 21 f0    	cmp    %edx,0xf0216e88
f01039ae:	0f 86 60 ff ff ff    	jbe    f0103914 <env_free+0x62>
	return (void *)(pa + KERNBASE);
f01039b4:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01039ba:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01039bd:	c1 e2 14             	shl    $0x14,%edx
f01039c0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01039c3:	8d b0 00 10 00 f0    	lea    -0xffff000(%eax),%esi
f01039c9:	f7 d8                	neg    %eax
f01039cb:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01039ce:	e9 5d ff ff ff       	jmp    f0103930 <env_free+0x7e>
		panic("pa2page called with invalid pa");
f01039d3:	83 ec 04             	sub    $0x4,%esp
f01039d6:	68 2c 78 10 f0       	push   $0xf010782c
f01039db:	6a 51                	push   $0x51
f01039dd:	68 a0 73 10 f0       	push   $0xf01073a0
f01039e2:	e8 59 c6 ff ff       	call   f0100040 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01039e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01039ea:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f01039ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01039f2:	76 52                	jbe    f0103a46 <env_free+0x194>
	e->env_pgdir = 0;
f01039f4:	8b 55 08             	mov    0x8(%ebp),%edx
f01039f7:	c7 42 60 00 00 00 00 	movl   $0x0,0x60(%edx)
	return (physaddr_t)kva - KERNBASE;
f01039fe:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103a03:	c1 e8 0c             	shr    $0xc,%eax
f0103a06:	3b 05 88 6e 21 f0    	cmp    0xf0216e88,%eax
f0103a0c:	73 4d                	jae    f0103a5b <env_free+0x1a9>
	page_decref(pa2page(pa));
f0103a0e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103a11:	8b 15 90 6e 21 f0    	mov    0xf0216e90,%edx
f0103a17:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103a1a:	50                   	push   %eax
f0103a1b:	e8 72 da ff ff       	call   f0101492 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103a20:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a23:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103a2a:	a1 48 62 21 f0       	mov    0xf0216248,%eax
f0103a2f:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a32:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103a35:	89 15 48 62 21 f0    	mov    %edx,0xf0216248
}
f0103a3b:	83 c4 10             	add    $0x10,%esp
f0103a3e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103a41:	5b                   	pop    %ebx
f0103a42:	5e                   	pop    %esi
f0103a43:	5f                   	pop    %edi
f0103a44:	5d                   	pop    %ebp
f0103a45:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a46:	50                   	push   %eax
f0103a47:	68 28 6b 10 f0       	push   $0xf0106b28
f0103a4c:	68 c4 01 00 00       	push   $0x1c4
f0103a51:	68 77 80 10 f0       	push   $0xf0108077
f0103a56:	e8 e5 c5 ff ff       	call   f0100040 <_panic>
		panic("pa2page called with invalid pa");
f0103a5b:	83 ec 04             	sub    $0x4,%esp
f0103a5e:	68 2c 78 10 f0       	push   $0xf010782c
f0103a63:	6a 51                	push   $0x51
f0103a65:	68 a0 73 10 f0       	push   $0xf01073a0
f0103a6a:	e8 d1 c5 ff ff       	call   f0100040 <_panic>

f0103a6f <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103a6f:	55                   	push   %ebp
f0103a70:	89 e5                	mov    %esp,%ebp
f0103a72:	53                   	push   %ebx
f0103a73:	83 ec 04             	sub    $0x4,%esp
f0103a76:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103a79:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103a7d:	74 21                	je     f0103aa0 <env_destroy+0x31>
		e->env_status = ENV_DYING;
		return;
	}

	env_free(e);
f0103a7f:	83 ec 0c             	sub    $0xc,%esp
f0103a82:	53                   	push   %ebx
f0103a83:	e8 2a fe ff ff       	call   f01038b2 <env_free>

	if (curenv == e) {
f0103a88:	e8 16 2a 00 00       	call   f01064a3 <cpunum>
f0103a8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a90:	83 c4 10             	add    $0x10,%esp
f0103a93:	39 98 28 70 21 f0    	cmp    %ebx,-0xfde8fd8(%eax)
f0103a99:	74 1e                	je     f0103ab9 <env_destroy+0x4a>
		curenv = NULL;
		sched_yield();
	}
}
f0103a9b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a9e:	c9                   	leave  
f0103a9f:	c3                   	ret    
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103aa0:	e8 fe 29 00 00       	call   f01064a3 <cpunum>
f0103aa5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103aa8:	39 98 28 70 21 f0    	cmp    %ebx,-0xfde8fd8(%eax)
f0103aae:	74 cf                	je     f0103a7f <env_destroy+0x10>
		e->env_status = ENV_DYING;
f0103ab0:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103ab7:	eb e2                	jmp    f0103a9b <env_destroy+0x2c>
		curenv = NULL;
f0103ab9:	e8 e5 29 00 00       	call   f01064a3 <cpunum>
f0103abe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ac1:	c7 80 28 70 21 f0 00 	movl   $0x0,-0xfde8fd8(%eax)
f0103ac8:	00 00 00 
		sched_yield();
f0103acb:	e8 25 11 00 00       	call   f0104bf5 <sched_yield>

f0103ad0 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103ad0:	55                   	push   %ebp
f0103ad1:	89 e5                	mov    %esp,%ebp
f0103ad3:	53                   	push   %ebx
f0103ad4:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103ad7:	e8 c7 29 00 00       	call   f01064a3 <cpunum>
f0103adc:	6b c0 74             	imul   $0x74,%eax,%eax
f0103adf:	8b 98 28 70 21 f0    	mov    -0xfde8fd8(%eax),%ebx
f0103ae5:	e8 b9 29 00 00       	call   f01064a3 <cpunum>
f0103aea:	89 43 5c             	mov    %eax,0x5c(%ebx)

	asm volatile(
f0103aed:	8b 65 08             	mov    0x8(%ebp),%esp
f0103af0:	61                   	popa   
f0103af1:	07                   	pop    %es
f0103af2:	1f                   	pop    %ds
f0103af3:	83 c4 08             	add    $0x8,%esp
f0103af6:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103af7:	83 ec 04             	sub    $0x4,%esp
f0103afa:	68 91 80 10 f0       	push   $0xf0108091
f0103aff:	68 fb 01 00 00       	push   $0x1fb
f0103b04:	68 77 80 10 f0       	push   $0xf0108077
f0103b09:	e8 32 c5 ff ff       	call   f0100040 <_panic>

f0103b0e <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103b0e:	55                   	push   %ebp
f0103b0f:	89 e5                	mov    %esp,%ebp
f0103b11:	83 ec 08             	sub    $0x8,%esp
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL){
f0103b14:	e8 8a 29 00 00       	call   f01064a3 <cpunum>
f0103b19:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b1c:	83 b8 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%eax)
f0103b23:	74 14                	je     f0103b39 <env_run+0x2b>
		if (curenv -> env_status == ENV_RUNNING)
f0103b25:	e8 79 29 00 00       	call   f01064a3 <cpunum>
f0103b2a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b2d:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103b33:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103b37:	74 65                	je     f0103b9e <env_run+0x90>
			curenv -> env_status = ENV_RUNNABLE;
	}
	curenv = e;
f0103b39:	e8 65 29 00 00       	call   f01064a3 <cpunum>
f0103b3e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b41:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b44:	89 90 28 70 21 f0    	mov    %edx,-0xfde8fd8(%eax)
	curenv -> env_status = ENV_RUNNING;
f0103b4a:	e8 54 29 00 00       	call   f01064a3 <cpunum>
f0103b4f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b52:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103b58:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv -> env_runs ++;
f0103b5f:	e8 3f 29 00 00       	call   f01064a3 <cpunum>
f0103b64:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b67:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103b6d:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv -> env_pgdir));
f0103b71:	e8 2d 29 00 00       	call   f01064a3 <cpunum>
f0103b76:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b79:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103b7f:	8b 40 60             	mov    0x60(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103b82:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b87:	77 2c                	ja     f0103bb5 <env_run+0xa7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b89:	50                   	push   %eax
f0103b8a:	68 28 6b 10 f0       	push   $0xf0106b28
f0103b8f:	68 20 02 00 00       	push   $0x220
f0103b94:	68 77 80 10 f0       	push   $0xf0108077
f0103b99:	e8 a2 c4 ff ff       	call   f0100040 <_panic>
			curenv -> env_status = ENV_RUNNABLE;
f0103b9e:	e8 00 29 00 00       	call   f01064a3 <cpunum>
f0103ba3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ba6:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0103bac:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
f0103bb3:	eb 84                	jmp    f0103b39 <env_run+0x2b>
	return (physaddr_t)kva - KERNBASE;
f0103bb5:	05 00 00 00 10       	add    $0x10000000,%eax
f0103bba:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103bbd:	83 ec 0c             	sub    $0xc,%esp
f0103bc0:	68 c0 33 12 f0       	push   $0xf01233c0
f0103bc5:	e8 e6 2b 00 00       	call   f01067b0 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103bca:	f3 90                	pause  

	// relase the lock before env_pop_tf()
	// LAB 4: Your code here.
	unlock_kernel();

	env_pop_tf(&(curenv -> env_tf));
f0103bcc:	e8 d2 28 00 00       	call   f01064a3 <cpunum>
f0103bd1:	83 c4 04             	add    $0x4,%esp
f0103bd4:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bd7:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0103bdd:	e8 ee fe ff ff       	call   f0103ad0 <env_pop_tf>

f0103be2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103be2:	55                   	push   %ebp
f0103be3:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103be5:	8b 45 08             	mov    0x8(%ebp),%eax
f0103be8:	ba 70 00 00 00       	mov    $0x70,%edx
f0103bed:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103bee:	ba 71 00 00 00       	mov    $0x71,%edx
f0103bf3:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103bf4:	0f b6 c0             	movzbl %al,%eax
}
f0103bf7:	5d                   	pop    %ebp
f0103bf8:	c3                   	ret    

f0103bf9 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103bf9:	55                   	push   %ebp
f0103bfa:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103bfc:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bff:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c04:	ee                   	out    %al,(%dx)
f0103c05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c08:	ba 71 00 00 00       	mov    $0x71,%edx
f0103c0d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103c0e:	5d                   	pop    %ebp
f0103c0f:	c3                   	ret    

f0103c10 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103c10:	55                   	push   %ebp
f0103c11:	89 e5                	mov    %esp,%ebp
f0103c13:	56                   	push   %esi
f0103c14:	53                   	push   %ebx
f0103c15:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103c18:	66 a3 a8 33 12 f0    	mov    %ax,0xf01233a8
	if (!didinit)
f0103c1e:	80 3d 4c 62 21 f0 00 	cmpb   $0x0,0xf021624c
f0103c25:	75 07                	jne    f0103c2e <irq_setmask_8259A+0x1e>
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
}
f0103c27:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103c2a:	5b                   	pop    %ebx
f0103c2b:	5e                   	pop    %esi
f0103c2c:	5d                   	pop    %ebp
f0103c2d:	c3                   	ret    
f0103c2e:	89 c6                	mov    %eax,%esi
f0103c30:	ba 21 00 00 00       	mov    $0x21,%edx
f0103c35:	ee                   	out    %al,(%dx)
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103c36:	66 c1 e8 08          	shr    $0x8,%ax
f0103c3a:	ba a1 00 00 00       	mov    $0xa1,%edx
f0103c3f:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103c40:	83 ec 0c             	sub    $0xc,%esp
f0103c43:	68 e9 80 10 f0       	push   $0xf01080e9
f0103c48:	e8 1e 01 00 00       	call   f0103d6b <cprintf>
f0103c4d:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103c50:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103c55:	0f b7 f6             	movzwl %si,%esi
f0103c58:	f7 d6                	not    %esi
f0103c5a:	eb 08                	jmp    f0103c64 <irq_setmask_8259A+0x54>
	for (i = 0; i < 16; i++)
f0103c5c:	83 c3 01             	add    $0x1,%ebx
f0103c5f:	83 fb 10             	cmp    $0x10,%ebx
f0103c62:	74 18                	je     f0103c7c <irq_setmask_8259A+0x6c>
		if (~mask & (1<<i))
f0103c64:	0f a3 de             	bt     %ebx,%esi
f0103c67:	73 f3                	jae    f0103c5c <irq_setmask_8259A+0x4c>
			cprintf(" %d", i);
f0103c69:	83 ec 08             	sub    $0x8,%esp
f0103c6c:	53                   	push   %ebx
f0103c6d:	68 8b 85 10 f0       	push   $0xf010858b
f0103c72:	e8 f4 00 00 00       	call   f0103d6b <cprintf>
f0103c77:	83 c4 10             	add    $0x10,%esp
f0103c7a:	eb e0                	jmp    f0103c5c <irq_setmask_8259A+0x4c>
	cprintf("\n");
f0103c7c:	83 ec 0c             	sub    $0xc,%esp
f0103c7f:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0103c84:	e8 e2 00 00 00       	call   f0103d6b <cprintf>
f0103c89:	83 c4 10             	add    $0x10,%esp
f0103c8c:	eb 99                	jmp    f0103c27 <irq_setmask_8259A+0x17>

f0103c8e <pic_init>:
{
f0103c8e:	55                   	push   %ebp
f0103c8f:	89 e5                	mov    %esp,%ebp
f0103c91:	57                   	push   %edi
f0103c92:	56                   	push   %esi
f0103c93:	53                   	push   %ebx
f0103c94:	83 ec 0c             	sub    $0xc,%esp
	didinit = 1;
f0103c97:	c6 05 4c 62 21 f0 01 	movb   $0x1,0xf021624c
f0103c9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ca3:	bb 21 00 00 00       	mov    $0x21,%ebx
f0103ca8:	89 da                	mov    %ebx,%edx
f0103caa:	ee                   	out    %al,(%dx)
f0103cab:	b9 a1 00 00 00       	mov    $0xa1,%ecx
f0103cb0:	89 ca                	mov    %ecx,%edx
f0103cb2:	ee                   	out    %al,(%dx)
f0103cb3:	bf 11 00 00 00       	mov    $0x11,%edi
f0103cb8:	be 20 00 00 00       	mov    $0x20,%esi
f0103cbd:	89 f8                	mov    %edi,%eax
f0103cbf:	89 f2                	mov    %esi,%edx
f0103cc1:	ee                   	out    %al,(%dx)
f0103cc2:	b8 20 00 00 00       	mov    $0x20,%eax
f0103cc7:	89 da                	mov    %ebx,%edx
f0103cc9:	ee                   	out    %al,(%dx)
f0103cca:	b8 04 00 00 00       	mov    $0x4,%eax
f0103ccf:	ee                   	out    %al,(%dx)
f0103cd0:	b8 03 00 00 00       	mov    $0x3,%eax
f0103cd5:	ee                   	out    %al,(%dx)
f0103cd6:	bb a0 00 00 00       	mov    $0xa0,%ebx
f0103cdb:	89 f8                	mov    %edi,%eax
f0103cdd:	89 da                	mov    %ebx,%edx
f0103cdf:	ee                   	out    %al,(%dx)
f0103ce0:	b8 28 00 00 00       	mov    $0x28,%eax
f0103ce5:	89 ca                	mov    %ecx,%edx
f0103ce7:	ee                   	out    %al,(%dx)
f0103ce8:	b8 02 00 00 00       	mov    $0x2,%eax
f0103ced:	ee                   	out    %al,(%dx)
f0103cee:	b8 01 00 00 00       	mov    $0x1,%eax
f0103cf3:	ee                   	out    %al,(%dx)
f0103cf4:	bf 68 00 00 00       	mov    $0x68,%edi
f0103cf9:	89 f8                	mov    %edi,%eax
f0103cfb:	89 f2                	mov    %esi,%edx
f0103cfd:	ee                   	out    %al,(%dx)
f0103cfe:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0103d03:	89 c8                	mov    %ecx,%eax
f0103d05:	ee                   	out    %al,(%dx)
f0103d06:	89 f8                	mov    %edi,%eax
f0103d08:	89 da                	mov    %ebx,%edx
f0103d0a:	ee                   	out    %al,(%dx)
f0103d0b:	89 c8                	mov    %ecx,%eax
f0103d0d:	ee                   	out    %al,(%dx)
	if (irq_mask_8259A != 0xFFFF)
f0103d0e:	0f b7 05 a8 33 12 f0 	movzwl 0xf01233a8,%eax
f0103d15:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103d19:	74 0f                	je     f0103d2a <pic_init+0x9c>
		irq_setmask_8259A(irq_mask_8259A);
f0103d1b:	83 ec 0c             	sub    $0xc,%esp
f0103d1e:	0f b7 c0             	movzwl %ax,%eax
f0103d21:	50                   	push   %eax
f0103d22:	e8 e9 fe ff ff       	call   f0103c10 <irq_setmask_8259A>
f0103d27:	83 c4 10             	add    $0x10,%esp
}
f0103d2a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103d2d:	5b                   	pop    %ebx
f0103d2e:	5e                   	pop    %esi
f0103d2f:	5f                   	pop    %edi
f0103d30:	5d                   	pop    %ebp
f0103d31:	c3                   	ret    

f0103d32 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103d32:	55                   	push   %ebp
f0103d33:	89 e5                	mov    %esp,%ebp
f0103d35:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103d38:	ff 75 08             	pushl  0x8(%ebp)
f0103d3b:	e8 62 ca ff ff       	call   f01007a2 <cputchar>
	*cnt++;
}
f0103d40:	83 c4 10             	add    $0x10,%esp
f0103d43:	c9                   	leave  
f0103d44:	c3                   	ret    

f0103d45 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103d45:	55                   	push   %ebp
f0103d46:	89 e5                	mov    %esp,%ebp
f0103d48:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103d4b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103d52:	ff 75 0c             	pushl  0xc(%ebp)
f0103d55:	ff 75 08             	pushl  0x8(%ebp)
f0103d58:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103d5b:	50                   	push   %eax
f0103d5c:	68 32 3d 10 f0       	push   $0xf0103d32
f0103d61:	e8 c6 19 00 00       	call   f010572c <vprintfmt>
	return cnt;
}
f0103d66:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103d69:	c9                   	leave  
f0103d6a:	c3                   	ret    

f0103d6b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103d6b:	55                   	push   %ebp
f0103d6c:	89 e5                	mov    %esp,%ebp
f0103d6e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103d71:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103d74:	50                   	push   %eax
f0103d75:	ff 75 08             	pushl  0x8(%ebp)
f0103d78:	e8 c8 ff ff ff       	call   f0103d45 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103d7d:	c9                   	leave  
f0103d7e:	c3                   	ret    

f0103d7f <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103d7f:	55                   	push   %ebp
f0103d80:	89 e5                	mov    %esp,%ebp
f0103d82:	57                   	push   %edi
f0103d83:	56                   	push   %esi
f0103d84:	53                   	push   %ebx
f0103d85:	83 ec 0c             	sub    $0xc,%esp
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:
	struct Taskstate *this_ts = &thiscpu->cpu_ts;
f0103d88:	e8 16 27 00 00       	call   f01064a3 <cpunum>
f0103d8d:	6b f0 74             	imul   $0x74,%eax,%esi
f0103d90:	8d 9e 2c 70 21 f0    	lea    -0xfde8fd4(%esi),%ebx
	uint8_t this_cpu_id = thiscpu->cpu_id; 
f0103d96:	e8 08 27 00 00       	call   f01064a3 <cpunum>
f0103d9b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9e:	0f b6 90 20 70 21 f0 	movzbl -0xfde8fe0(%eax),%edx
	
	this_ts->ts_esp0 = KSTACKTOP - this_cpu_id * (KSTKSIZE + KSTKGAP);
f0103da5:	0f b6 c2             	movzbl %dl,%eax
f0103da8:	89 c7                	mov    %eax,%edi
f0103daa:	c1 e7 10             	shl    $0x10,%edi
f0103dad:	b9 00 00 00 f0       	mov    $0xf0000000,%ecx
f0103db2:	29 f9                	sub    %edi,%ecx
f0103db4:	89 8e 30 70 21 f0    	mov    %ecx,-0xfde8fd0(%esi)
	this_ts->ts_ss0 = GD_KD;
f0103dba:	66 c7 86 34 70 21 f0 	movw   $0x10,-0xfde8fcc(%esi)
f0103dc1:	10 00 
	this_ts->ts_iomb = sizeof(struct Taskstate);
f0103dc3:	66 c7 86 92 70 21 f0 	movw   $0x68,-0xfde8f6e(%esi)
f0103dca:	68 00 

	gdt[(GD_TSS0 >> 3) + this_cpu_id] = SEG16(STS_T32A, (uint32_t)(this_ts),
f0103dcc:	83 c0 05             	add    $0x5,%eax
f0103dcf:	66 c7 04 c5 40 33 12 	movw   $0x67,-0xfedccc0(,%eax,8)
f0103dd6:	f0 67 00 
f0103dd9:	66 89 1c c5 42 33 12 	mov    %bx,-0xfedccbe(,%eax,8)
f0103de0:	f0 
f0103de1:	89 d9                	mov    %ebx,%ecx
f0103de3:	c1 e9 10             	shr    $0x10,%ecx
f0103de6:	88 0c c5 44 33 12 f0 	mov    %cl,-0xfedccbc(,%eax,8)
f0103ded:	c6 04 c5 46 33 12 f0 	movb   $0x40,-0xfedccba(,%eax,8)
f0103df4:	40 
f0103df5:	c1 eb 18             	shr    $0x18,%ebx
f0103df8:	88 1c c5 47 33 12 f0 	mov    %bl,-0xfedccb9(,%eax,8)
					sizeof(struct Taskstate) - 1, 0);
	gdt[(GD_TSS0 >> 3) + this_cpu_id].sd_s = 0;
f0103dff:	c6 04 c5 45 33 12 f0 	movb   $0x89,-0xfedccbb(,%eax,8)
f0103e06:	89 

	ltr(GD_TSS0 + (this_cpu_id << 3));
f0103e07:	0f b6 d2             	movzbl %dl,%edx
f0103e0a:	8d 14 d5 28 00 00 00 	lea    0x28(,%edx,8),%edx
	asm volatile("ltr %0" : : "r" (sel));
f0103e11:	0f 00 da             	ltr    %dx
	asm volatile("lidt (%0)" : : "r" (p));
f0103e14:	b8 ac 33 12 f0       	mov    $0xf01233ac,%eax
f0103e19:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd);

}
f0103e1c:	83 c4 0c             	add    $0xc,%esp
f0103e1f:	5b                   	pop    %ebx
f0103e20:	5e                   	pop    %esi
f0103e21:	5f                   	pop    %edi
f0103e22:	5d                   	pop    %ebp
f0103e23:	c3                   	ret    

f0103e24 <trap_init>:
{
f0103e24:	55                   	push   %ebp
f0103e25:	89 e5                	mov    %esp,%ebp
f0103e27:	83 ec 08             	sub    $0x8,%esp
	SETGATE(idt[T_DIVIDE], 0, GD_KT, T_DIVIDE_H, 0);
f0103e2a:	b8 40 4a 10 f0       	mov    $0xf0104a40,%eax
f0103e2f:	66 a3 60 62 21 f0    	mov    %ax,0xf0216260
f0103e35:	66 c7 05 62 62 21 f0 	movw   $0x8,0xf0216262
f0103e3c:	08 00 
f0103e3e:	c6 05 64 62 21 f0 00 	movb   $0x0,0xf0216264
f0103e45:	c6 05 65 62 21 f0 8e 	movb   $0x8e,0xf0216265
f0103e4c:	c1 e8 10             	shr    $0x10,%eax
f0103e4f:	66 a3 66 62 21 f0    	mov    %ax,0xf0216266
	SETGATE(idt[T_DEBUG], 0, GD_KT, T_DEBUG_H, 0);
f0103e55:	b8 4a 4a 10 f0       	mov    $0xf0104a4a,%eax
f0103e5a:	66 a3 68 62 21 f0    	mov    %ax,0xf0216268
f0103e60:	66 c7 05 6a 62 21 f0 	movw   $0x8,0xf021626a
f0103e67:	08 00 
f0103e69:	c6 05 6c 62 21 f0 00 	movb   $0x0,0xf021626c
f0103e70:	c6 05 6d 62 21 f0 8e 	movb   $0x8e,0xf021626d
f0103e77:	c1 e8 10             	shr    $0x10,%eax
f0103e7a:	66 a3 6e 62 21 f0    	mov    %ax,0xf021626e
	SETGATE(idt[T_NMI], 0, GD_KT, T_NMI_H, 0);
f0103e80:	b8 54 4a 10 f0       	mov    $0xf0104a54,%eax
f0103e85:	66 a3 70 62 21 f0    	mov    %ax,0xf0216270
f0103e8b:	66 c7 05 72 62 21 f0 	movw   $0x8,0xf0216272
f0103e92:	08 00 
f0103e94:	c6 05 74 62 21 f0 00 	movb   $0x0,0xf0216274
f0103e9b:	c6 05 75 62 21 f0 8e 	movb   $0x8e,0xf0216275
f0103ea2:	c1 e8 10             	shr    $0x10,%eax
f0103ea5:	66 a3 76 62 21 f0    	mov    %ax,0xf0216276
	SETGATE(idt[T_BRKPT], 0, GD_KT, T_BRKPT_H, 3);
f0103eab:	b8 5e 4a 10 f0       	mov    $0xf0104a5e,%eax
f0103eb0:	66 a3 78 62 21 f0    	mov    %ax,0xf0216278
f0103eb6:	66 c7 05 7a 62 21 f0 	movw   $0x8,0xf021627a
f0103ebd:	08 00 
f0103ebf:	c6 05 7c 62 21 f0 00 	movb   $0x0,0xf021627c
f0103ec6:	c6 05 7d 62 21 f0 ee 	movb   $0xee,0xf021627d
f0103ecd:	c1 e8 10             	shr    $0x10,%eax
f0103ed0:	66 a3 7e 62 21 f0    	mov    %ax,0xf021627e
	SETGATE(idt[T_OFLOW], 0, GD_KT, T_OFLOW_H, 0);
f0103ed6:	b8 68 4a 10 f0       	mov    $0xf0104a68,%eax
f0103edb:	66 a3 80 62 21 f0    	mov    %ax,0xf0216280
f0103ee1:	66 c7 05 82 62 21 f0 	movw   $0x8,0xf0216282
f0103ee8:	08 00 
f0103eea:	c6 05 84 62 21 f0 00 	movb   $0x0,0xf0216284
f0103ef1:	c6 05 85 62 21 f0 8e 	movb   $0x8e,0xf0216285
f0103ef8:	c1 e8 10             	shr    $0x10,%eax
f0103efb:	66 a3 86 62 21 f0    	mov    %ax,0xf0216286
	SETGATE(idt[T_BOUND], 0, GD_KT, T_BOUND_H, 0);
f0103f01:	b8 72 4a 10 f0       	mov    $0xf0104a72,%eax
f0103f06:	66 a3 88 62 21 f0    	mov    %ax,0xf0216288
f0103f0c:	66 c7 05 8a 62 21 f0 	movw   $0x8,0xf021628a
f0103f13:	08 00 
f0103f15:	c6 05 8c 62 21 f0 00 	movb   $0x0,0xf021628c
f0103f1c:	c6 05 8d 62 21 f0 8e 	movb   $0x8e,0xf021628d
f0103f23:	c1 e8 10             	shr    $0x10,%eax
f0103f26:	66 a3 8e 62 21 f0    	mov    %ax,0xf021628e
	SETGATE(idt[T_ILLOP], 0, GD_KT, T_ILLOP_H, 0);
f0103f2c:	b8 86 4a 10 f0       	mov    $0xf0104a86,%eax
f0103f31:	66 a3 90 62 21 f0    	mov    %ax,0xf0216290
f0103f37:	66 c7 05 92 62 21 f0 	movw   $0x8,0xf0216292
f0103f3e:	08 00 
f0103f40:	c6 05 94 62 21 f0 00 	movb   $0x0,0xf0216294
f0103f47:	c6 05 95 62 21 f0 8e 	movb   $0x8e,0xf0216295
f0103f4e:	c1 e8 10             	shr    $0x10,%eax
f0103f51:	66 a3 96 62 21 f0    	mov    %ax,0xf0216296
	SETGATE(idt[T_DEVICE], 0, GD_KT, T_DEVICE_H, 0);
f0103f57:	b8 7c 4a 10 f0       	mov    $0xf0104a7c,%eax
f0103f5c:	66 a3 98 62 21 f0    	mov    %ax,0xf0216298
f0103f62:	66 c7 05 9a 62 21 f0 	movw   $0x8,0xf021629a
f0103f69:	08 00 
f0103f6b:	c6 05 9c 62 21 f0 00 	movb   $0x0,0xf021629c
f0103f72:	c6 05 9d 62 21 f0 8e 	movb   $0x8e,0xf021629d
f0103f79:	c1 e8 10             	shr    $0x10,%eax
f0103f7c:	66 a3 9e 62 21 f0    	mov    %ax,0xf021629e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, T_DBLFLT_H, 0);
f0103f82:	b8 08 4a 10 f0       	mov    $0xf0104a08,%eax
f0103f87:	66 a3 a0 62 21 f0    	mov    %ax,0xf02162a0
f0103f8d:	66 c7 05 a2 62 21 f0 	movw   $0x8,0xf02162a2
f0103f94:	08 00 
f0103f96:	c6 05 a4 62 21 f0 00 	movb   $0x0,0xf02162a4
f0103f9d:	c6 05 a5 62 21 f0 8e 	movb   $0x8e,0xf02162a5
f0103fa4:	c1 e8 10             	shr    $0x10,%eax
f0103fa7:	66 a3 a6 62 21 f0    	mov    %ax,0xf02162a6
	SETGATE(idt[T_TSS], 0, GD_KT, T_TSS_H, 0);
f0103fad:	b8 10 4a 10 f0       	mov    $0xf0104a10,%eax
f0103fb2:	66 a3 b0 62 21 f0    	mov    %ax,0xf02162b0
f0103fb8:	66 c7 05 b2 62 21 f0 	movw   $0x8,0xf02162b2
f0103fbf:	08 00 
f0103fc1:	c6 05 b4 62 21 f0 00 	movb   $0x0,0xf02162b4
f0103fc8:	c6 05 b5 62 21 f0 8e 	movb   $0x8e,0xf02162b5
f0103fcf:	c1 e8 10             	shr    $0x10,%eax
f0103fd2:	66 a3 b6 62 21 f0    	mov    %ax,0xf02162b6
	SETGATE(idt[T_SEGNP], 0, GD_KT, T_SEGNP_H, 0);
f0103fd8:	b8 18 4a 10 f0       	mov    $0xf0104a18,%eax
f0103fdd:	66 a3 b8 62 21 f0    	mov    %ax,0xf02162b8
f0103fe3:	66 c7 05 ba 62 21 f0 	movw   $0x8,0xf02162ba
f0103fea:	08 00 
f0103fec:	c6 05 bc 62 21 f0 00 	movb   $0x0,0xf02162bc
f0103ff3:	c6 05 bd 62 21 f0 8e 	movb   $0x8e,0xf02162bd
f0103ffa:	c1 e8 10             	shr    $0x10,%eax
f0103ffd:	66 a3 be 62 21 f0    	mov    %ax,0xf02162be
	SETGATE(idt[T_STACK], 0, GD_KT, T_STACK_H, 0);
f0104003:	b8 20 4a 10 f0       	mov    $0xf0104a20,%eax
f0104008:	66 a3 c0 62 21 f0    	mov    %ax,0xf02162c0
f010400e:	66 c7 05 c2 62 21 f0 	movw   $0x8,0xf02162c2
f0104015:	08 00 
f0104017:	c6 05 c4 62 21 f0 00 	movb   $0x0,0xf02162c4
f010401e:	c6 05 c5 62 21 f0 8e 	movb   $0x8e,0xf02162c5
f0104025:	c1 e8 10             	shr    $0x10,%eax
f0104028:	66 a3 c6 62 21 f0    	mov    %ax,0xf02162c6
	SETGATE(idt[T_GPFLT], 0, GD_KT, T_GPFLT_H, 0);
f010402e:	b8 28 4a 10 f0       	mov    $0xf0104a28,%eax
f0104033:	66 a3 c8 62 21 f0    	mov    %ax,0xf02162c8
f0104039:	66 c7 05 ca 62 21 f0 	movw   $0x8,0xf02162ca
f0104040:	08 00 
f0104042:	c6 05 cc 62 21 f0 00 	movb   $0x0,0xf02162cc
f0104049:	c6 05 cd 62 21 f0 8e 	movb   $0x8e,0xf02162cd
f0104050:	c1 e8 10             	shr    $0x10,%eax
f0104053:	66 a3 ce 62 21 f0    	mov    %ax,0xf02162ce
	SETGATE(idt[T_PGFLT], 0, GD_KT, T_PGFLT_H, 0);
f0104059:	b8 30 4a 10 f0       	mov    $0xf0104a30,%eax
f010405e:	66 a3 d0 62 21 f0    	mov    %ax,0xf02162d0
f0104064:	66 c7 05 d2 62 21 f0 	movw   $0x8,0xf02162d2
f010406b:	08 00 
f010406d:	c6 05 d4 62 21 f0 00 	movb   $0x0,0xf02162d4
f0104074:	c6 05 d5 62 21 f0 8e 	movb   $0x8e,0xf02162d5
f010407b:	c1 e8 10             	shr    $0x10,%eax
f010407e:	66 a3 d6 62 21 f0    	mov    %ax,0xf02162d6
	SETGATE(idt[T_FPERR], 0, GD_KT, T_FPERR_H, 0);
f0104084:	b8 90 4a 10 f0       	mov    $0xf0104a90,%eax
f0104089:	66 a3 e0 62 21 f0    	mov    %ax,0xf02162e0
f010408f:	66 c7 05 e2 62 21 f0 	movw   $0x8,0xf02162e2
f0104096:	08 00 
f0104098:	c6 05 e4 62 21 f0 00 	movb   $0x0,0xf02162e4
f010409f:	c6 05 e5 62 21 f0 8e 	movb   $0x8e,0xf02162e5
f01040a6:	c1 e8 10             	shr    $0x10,%eax
f01040a9:	66 a3 e6 62 21 f0    	mov    %ax,0xf02162e6
	SETGATE(idt[T_ALIGN], 0, GD_KT, T_ALIGN_H, 0);
f01040af:	b8 38 4a 10 f0       	mov    $0xf0104a38,%eax
f01040b4:	66 a3 e8 62 21 f0    	mov    %ax,0xf02162e8
f01040ba:	66 c7 05 ea 62 21 f0 	movw   $0x8,0xf02162ea
f01040c1:	08 00 
f01040c3:	c6 05 ec 62 21 f0 00 	movb   $0x0,0xf02162ec
f01040ca:	c6 05 ed 62 21 f0 8e 	movb   $0x8e,0xf02162ed
f01040d1:	c1 e8 10             	shr    $0x10,%eax
f01040d4:	66 a3 ee 62 21 f0    	mov    %ax,0xf02162ee
	SETGATE(idt[T_MCHK], 0, GD_KT, T_MCHK_H, 0);
f01040da:	b8 96 4a 10 f0       	mov    $0xf0104a96,%eax
f01040df:	66 a3 f0 62 21 f0    	mov    %ax,0xf02162f0
f01040e5:	66 c7 05 f2 62 21 f0 	movw   $0x8,0xf02162f2
f01040ec:	08 00 
f01040ee:	c6 05 f4 62 21 f0 00 	movb   $0x0,0xf02162f4
f01040f5:	c6 05 f5 62 21 f0 8e 	movb   $0x8e,0xf02162f5
f01040fc:	c1 e8 10             	shr    $0x10,%eax
f01040ff:	66 a3 f6 62 21 f0    	mov    %ax,0xf02162f6
	SETGATE(idt[T_SIMDERR], 0, GD_KT, T_SIMDERR_H, 0);
f0104105:	b8 9c 4a 10 f0       	mov    $0xf0104a9c,%eax
f010410a:	66 a3 f8 62 21 f0    	mov    %ax,0xf02162f8
f0104110:	66 c7 05 fa 62 21 f0 	movw   $0x8,0xf02162fa
f0104117:	08 00 
f0104119:	c6 05 fc 62 21 f0 00 	movb   $0x0,0xf02162fc
f0104120:	c6 05 fd 62 21 f0 8e 	movb   $0x8e,0xf02162fd
f0104127:	c1 e8 10             	shr    $0x10,%eax
f010412a:	66 a3 fe 62 21 f0    	mov    %ax,0xf02162fe
	SETGATE(idt[T_SYSCALL], 0, GD_KT, T_SYSCALL_H, 3);
f0104130:	b8 a2 4a 10 f0       	mov    $0xf0104aa2,%eax
f0104135:	66 a3 e0 63 21 f0    	mov    %ax,0xf02163e0
f010413b:	66 c7 05 e2 63 21 f0 	movw   $0x8,0xf02163e2
f0104142:	08 00 
f0104144:	c6 05 e4 63 21 f0 00 	movb   $0x0,0xf02163e4
f010414b:	c6 05 e5 63 21 f0 ee 	movb   $0xee,0xf02163e5
f0104152:	c1 e8 10             	shr    $0x10,%eax
f0104155:	66 a3 e6 63 21 f0    	mov    %ax,0xf02163e6
	SETGATE(idt[T_DEFAULT], 0, GD_KT, T_DEFAULT_H, 0);
f010415b:	b8 a8 4a 10 f0       	mov    $0xf0104aa8,%eax
f0104160:	66 a3 00 72 21 f0    	mov    %ax,0xf0217200
f0104166:	66 c7 05 02 72 21 f0 	movw   $0x8,0xf0217202
f010416d:	08 00 
f010416f:	c6 05 04 72 21 f0 00 	movb   $0x0,0xf0217204
f0104176:	c6 05 05 72 21 f0 8e 	movb   $0x8e,0xf0217205
f010417d:	c1 e8 10             	shr    $0x10,%eax
f0104180:	66 a3 06 72 21 f0    	mov    %ax,0xf0217206
	SETGATE(idt[IRQ_OFFSET + 0], 0, GD_KT, IRQ_0_H, 0);
f0104186:	b8 b2 4a 10 f0       	mov    $0xf0104ab2,%eax
f010418b:	66 a3 60 63 21 f0    	mov    %ax,0xf0216360
f0104191:	66 c7 05 62 63 21 f0 	movw   $0x8,0xf0216362
f0104198:	08 00 
f010419a:	c6 05 64 63 21 f0 00 	movb   $0x0,0xf0216364
f01041a1:	c6 05 65 63 21 f0 8e 	movb   $0x8e,0xf0216365
f01041a8:	c1 e8 10             	shr    $0x10,%eax
f01041ab:	66 a3 66 63 21 f0    	mov    %ax,0xf0216366
	SETGATE(idt[IRQ_OFFSET + 1], 0, GD_KT, IRQ_1_H, 0);
f01041b1:	b8 b8 4a 10 f0       	mov    $0xf0104ab8,%eax
f01041b6:	66 a3 68 63 21 f0    	mov    %ax,0xf0216368
f01041bc:	66 c7 05 6a 63 21 f0 	movw   $0x8,0xf021636a
f01041c3:	08 00 
f01041c5:	c6 05 6c 63 21 f0 00 	movb   $0x0,0xf021636c
f01041cc:	c6 05 6d 63 21 f0 8e 	movb   $0x8e,0xf021636d
f01041d3:	c1 e8 10             	shr    $0x10,%eax
f01041d6:	66 a3 6e 63 21 f0    	mov    %ax,0xf021636e
	SETGATE(idt[IRQ_OFFSET + 2], 0, GD_KT, IRQ_2_H, 0);
f01041dc:	b8 be 4a 10 f0       	mov    $0xf0104abe,%eax
f01041e1:	66 a3 70 63 21 f0    	mov    %ax,0xf0216370
f01041e7:	66 c7 05 72 63 21 f0 	movw   $0x8,0xf0216372
f01041ee:	08 00 
f01041f0:	c6 05 74 63 21 f0 00 	movb   $0x0,0xf0216374
f01041f7:	c6 05 75 63 21 f0 8e 	movb   $0x8e,0xf0216375
f01041fe:	c1 e8 10             	shr    $0x10,%eax
f0104201:	66 a3 76 63 21 f0    	mov    %ax,0xf0216376
	SETGATE(idt[IRQ_OFFSET + 3], 0, GD_KT, IRQ_3_H, 0);
f0104207:	b8 c4 4a 10 f0       	mov    $0xf0104ac4,%eax
f010420c:	66 a3 78 63 21 f0    	mov    %ax,0xf0216378
f0104212:	66 c7 05 7a 63 21 f0 	movw   $0x8,0xf021637a
f0104219:	08 00 
f010421b:	c6 05 7c 63 21 f0 00 	movb   $0x0,0xf021637c
f0104222:	c6 05 7d 63 21 f0 8e 	movb   $0x8e,0xf021637d
f0104229:	c1 e8 10             	shr    $0x10,%eax
f010422c:	66 a3 7e 63 21 f0    	mov    %ax,0xf021637e
	SETGATE(idt[IRQ_OFFSET + 4], 0, GD_KT, IRQ_4_H, 0);
f0104232:	b8 ca 4a 10 f0       	mov    $0xf0104aca,%eax
f0104237:	66 a3 80 63 21 f0    	mov    %ax,0xf0216380
f010423d:	66 c7 05 82 63 21 f0 	movw   $0x8,0xf0216382
f0104244:	08 00 
f0104246:	c6 05 84 63 21 f0 00 	movb   $0x0,0xf0216384
f010424d:	c6 05 85 63 21 f0 8e 	movb   $0x8e,0xf0216385
f0104254:	c1 e8 10             	shr    $0x10,%eax
f0104257:	66 a3 86 63 21 f0    	mov    %ax,0xf0216386
	SETGATE(idt[IRQ_OFFSET + 5], 0, GD_KT, IRQ_5_H, 0);
f010425d:	b8 d0 4a 10 f0       	mov    $0xf0104ad0,%eax
f0104262:	66 a3 88 63 21 f0    	mov    %ax,0xf0216388
f0104268:	66 c7 05 8a 63 21 f0 	movw   $0x8,0xf021638a
f010426f:	08 00 
f0104271:	c6 05 8c 63 21 f0 00 	movb   $0x0,0xf021638c
f0104278:	c6 05 8d 63 21 f0 8e 	movb   $0x8e,0xf021638d
f010427f:	c1 e8 10             	shr    $0x10,%eax
f0104282:	66 a3 8e 63 21 f0    	mov    %ax,0xf021638e
	SETGATE(idt[IRQ_OFFSET + 6], 0, GD_KT, IRQ_6_H, 0);
f0104288:	b8 d6 4a 10 f0       	mov    $0xf0104ad6,%eax
f010428d:	66 a3 90 63 21 f0    	mov    %ax,0xf0216390
f0104293:	66 c7 05 92 63 21 f0 	movw   $0x8,0xf0216392
f010429a:	08 00 
f010429c:	c6 05 94 63 21 f0 00 	movb   $0x0,0xf0216394
f01042a3:	c6 05 95 63 21 f0 8e 	movb   $0x8e,0xf0216395
f01042aa:	c1 e8 10             	shr    $0x10,%eax
f01042ad:	66 a3 96 63 21 f0    	mov    %ax,0xf0216396
	SETGATE(idt[IRQ_OFFSET + 7], 0, GD_KT, IRQ_7_H, 0);
f01042b3:	b8 dc 4a 10 f0       	mov    $0xf0104adc,%eax
f01042b8:	66 a3 98 63 21 f0    	mov    %ax,0xf0216398
f01042be:	66 c7 05 9a 63 21 f0 	movw   $0x8,0xf021639a
f01042c5:	08 00 
f01042c7:	c6 05 9c 63 21 f0 00 	movb   $0x0,0xf021639c
f01042ce:	c6 05 9d 63 21 f0 8e 	movb   $0x8e,0xf021639d
f01042d5:	c1 e8 10             	shr    $0x10,%eax
f01042d8:	66 a3 9e 63 21 f0    	mov    %ax,0xf021639e
	SETGATE(idt[IRQ_OFFSET + 8], 0, GD_KT, IRQ_8_H, 0);
f01042de:	b8 e2 4a 10 f0       	mov    $0xf0104ae2,%eax
f01042e3:	66 a3 a0 63 21 f0    	mov    %ax,0xf02163a0
f01042e9:	66 c7 05 a2 63 21 f0 	movw   $0x8,0xf02163a2
f01042f0:	08 00 
f01042f2:	c6 05 a4 63 21 f0 00 	movb   $0x0,0xf02163a4
f01042f9:	c6 05 a5 63 21 f0 8e 	movb   $0x8e,0xf02163a5
f0104300:	c1 e8 10             	shr    $0x10,%eax
f0104303:	66 a3 a6 63 21 f0    	mov    %ax,0xf02163a6
	SETGATE(idt[IRQ_OFFSET + 9], 0, GD_KT, IRQ_9_H, 0);
f0104309:	b8 e8 4a 10 f0       	mov    $0xf0104ae8,%eax
f010430e:	66 a3 a8 63 21 f0    	mov    %ax,0xf02163a8
f0104314:	66 c7 05 aa 63 21 f0 	movw   $0x8,0xf02163aa
f010431b:	08 00 
f010431d:	c6 05 ac 63 21 f0 00 	movb   $0x0,0xf02163ac
f0104324:	c6 05 ad 63 21 f0 8e 	movb   $0x8e,0xf02163ad
f010432b:	c1 e8 10             	shr    $0x10,%eax
f010432e:	66 a3 ae 63 21 f0    	mov    %ax,0xf02163ae
	SETGATE(idt[IRQ_OFFSET + 10], 0, GD_KT, IRQ_10_H, 0);
f0104334:	b8 ee 4a 10 f0       	mov    $0xf0104aee,%eax
f0104339:	66 a3 b0 63 21 f0    	mov    %ax,0xf02163b0
f010433f:	66 c7 05 b2 63 21 f0 	movw   $0x8,0xf02163b2
f0104346:	08 00 
f0104348:	c6 05 b4 63 21 f0 00 	movb   $0x0,0xf02163b4
f010434f:	c6 05 b5 63 21 f0 8e 	movb   $0x8e,0xf02163b5
f0104356:	c1 e8 10             	shr    $0x10,%eax
f0104359:	66 a3 b6 63 21 f0    	mov    %ax,0xf02163b6
	SETGATE(idt[IRQ_OFFSET + 11], 0, GD_KT, IRQ_11_H, 0);
f010435f:	b8 f4 4a 10 f0       	mov    $0xf0104af4,%eax
f0104364:	66 a3 b8 63 21 f0    	mov    %ax,0xf02163b8
f010436a:	66 c7 05 ba 63 21 f0 	movw   $0x8,0xf02163ba
f0104371:	08 00 
f0104373:	c6 05 bc 63 21 f0 00 	movb   $0x0,0xf02163bc
f010437a:	c6 05 bd 63 21 f0 8e 	movb   $0x8e,0xf02163bd
f0104381:	c1 e8 10             	shr    $0x10,%eax
f0104384:	66 a3 be 63 21 f0    	mov    %ax,0xf02163be
	SETGATE(idt[IRQ_OFFSET + 12], 0, GD_KT, IRQ_12_H, 0);
f010438a:	b8 fa 4a 10 f0       	mov    $0xf0104afa,%eax
f010438f:	66 a3 c0 63 21 f0    	mov    %ax,0xf02163c0
f0104395:	66 c7 05 c2 63 21 f0 	movw   $0x8,0xf02163c2
f010439c:	08 00 
f010439e:	c6 05 c4 63 21 f0 00 	movb   $0x0,0xf02163c4
f01043a5:	c6 05 c5 63 21 f0 8e 	movb   $0x8e,0xf02163c5
f01043ac:	c1 e8 10             	shr    $0x10,%eax
f01043af:	66 a3 c6 63 21 f0    	mov    %ax,0xf02163c6
	SETGATE(idt[IRQ_OFFSET + 13], 0, GD_KT, IRQ_13_H, 0);
f01043b5:	b8 00 4b 10 f0       	mov    $0xf0104b00,%eax
f01043ba:	66 a3 c8 63 21 f0    	mov    %ax,0xf02163c8
f01043c0:	66 c7 05 ca 63 21 f0 	movw   $0x8,0xf02163ca
f01043c7:	08 00 
f01043c9:	c6 05 cc 63 21 f0 00 	movb   $0x0,0xf02163cc
f01043d0:	c6 05 cd 63 21 f0 8e 	movb   $0x8e,0xf02163cd
f01043d7:	c1 e8 10             	shr    $0x10,%eax
f01043da:	66 a3 ce 63 21 f0    	mov    %ax,0xf02163ce
	SETGATE(idt[IRQ_OFFSET + 14], 0, GD_KT, IRQ_14_H, 0);
f01043e0:	b8 06 4b 10 f0       	mov    $0xf0104b06,%eax
f01043e5:	66 a3 d0 63 21 f0    	mov    %ax,0xf02163d0
f01043eb:	66 c7 05 d2 63 21 f0 	movw   $0x8,0xf02163d2
f01043f2:	08 00 
f01043f4:	c6 05 d4 63 21 f0 00 	movb   $0x0,0xf02163d4
f01043fb:	c6 05 d5 63 21 f0 8e 	movb   $0x8e,0xf02163d5
f0104402:	c1 e8 10             	shr    $0x10,%eax
f0104405:	66 a3 d6 63 21 f0    	mov    %ax,0xf02163d6
	SETGATE(idt[IRQ_OFFSET + 15], 0, GD_KT, IRQ_15_H, 0);
f010440b:	b8 0c 4b 10 f0       	mov    $0xf0104b0c,%eax
f0104410:	66 a3 d8 63 21 f0    	mov    %ax,0xf02163d8
f0104416:	66 c7 05 da 63 21 f0 	movw   $0x8,0xf02163da
f010441d:	08 00 
f010441f:	c6 05 dc 63 21 f0 00 	movb   $0x0,0xf02163dc
f0104426:	c6 05 dd 63 21 f0 8e 	movb   $0x8e,0xf02163dd
f010442d:	c1 e8 10             	shr    $0x10,%eax
f0104430:	66 a3 de 63 21 f0    	mov    %ax,0xf02163de
	trap_init_percpu();
f0104436:	e8 44 f9 ff ff       	call   f0103d7f <trap_init_percpu>
}
f010443b:	c9                   	leave  
f010443c:	c3                   	ret    

f010443d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010443d:	55                   	push   %ebp
f010443e:	89 e5                	mov    %esp,%ebp
f0104440:	53                   	push   %ebx
f0104441:	83 ec 0c             	sub    $0xc,%esp
f0104444:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104447:	ff 33                	pushl  (%ebx)
f0104449:	68 fd 80 10 f0       	push   $0xf01080fd
f010444e:	e8 18 f9 ff ff       	call   f0103d6b <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104453:	83 c4 08             	add    $0x8,%esp
f0104456:	ff 73 04             	pushl  0x4(%ebx)
f0104459:	68 0c 81 10 f0       	push   $0xf010810c
f010445e:	e8 08 f9 ff ff       	call   f0103d6b <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104463:	83 c4 08             	add    $0x8,%esp
f0104466:	ff 73 08             	pushl  0x8(%ebx)
f0104469:	68 1b 81 10 f0       	push   $0xf010811b
f010446e:	e8 f8 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104473:	83 c4 08             	add    $0x8,%esp
f0104476:	ff 73 0c             	pushl  0xc(%ebx)
f0104479:	68 2a 81 10 f0       	push   $0xf010812a
f010447e:	e8 e8 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104483:	83 c4 08             	add    $0x8,%esp
f0104486:	ff 73 10             	pushl  0x10(%ebx)
f0104489:	68 39 81 10 f0       	push   $0xf0108139
f010448e:	e8 d8 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104493:	83 c4 08             	add    $0x8,%esp
f0104496:	ff 73 14             	pushl  0x14(%ebx)
f0104499:	68 48 81 10 f0       	push   $0xf0108148
f010449e:	e8 c8 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01044a3:	83 c4 08             	add    $0x8,%esp
f01044a6:	ff 73 18             	pushl  0x18(%ebx)
f01044a9:	68 57 81 10 f0       	push   $0xf0108157
f01044ae:	e8 b8 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01044b3:	83 c4 08             	add    $0x8,%esp
f01044b6:	ff 73 1c             	pushl  0x1c(%ebx)
f01044b9:	68 66 81 10 f0       	push   $0xf0108166
f01044be:	e8 a8 f8 ff ff       	call   f0103d6b <cprintf>
}
f01044c3:	83 c4 10             	add    $0x10,%esp
f01044c6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01044c9:	c9                   	leave  
f01044ca:	c3                   	ret    

f01044cb <print_trapframe>:
{
f01044cb:	55                   	push   %ebp
f01044cc:	89 e5                	mov    %esp,%ebp
f01044ce:	56                   	push   %esi
f01044cf:	53                   	push   %ebx
f01044d0:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f01044d3:	e8 cb 1f 00 00       	call   f01064a3 <cpunum>
f01044d8:	83 ec 04             	sub    $0x4,%esp
f01044db:	50                   	push   %eax
f01044dc:	53                   	push   %ebx
f01044dd:	68 ca 81 10 f0       	push   $0xf01081ca
f01044e2:	e8 84 f8 ff ff       	call   f0103d6b <cprintf>
	print_regs(&tf->tf_regs);
f01044e7:	89 1c 24             	mov    %ebx,(%esp)
f01044ea:	e8 4e ff ff ff       	call   f010443d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01044ef:	83 c4 08             	add    $0x8,%esp
f01044f2:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f01044f6:	50                   	push   %eax
f01044f7:	68 e8 81 10 f0       	push   $0xf01081e8
f01044fc:	e8 6a f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104501:	83 c4 08             	add    $0x8,%esp
f0104504:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104508:	50                   	push   %eax
f0104509:	68 fb 81 10 f0       	push   $0xf01081fb
f010450e:	e8 58 f8 ff ff       	call   f0103d6b <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104513:	8b 43 28             	mov    0x28(%ebx),%eax
	if (trapno < ARRAY_SIZE(excnames))
f0104516:	83 c4 10             	add    $0x10,%esp
f0104519:	83 f8 13             	cmp    $0x13,%eax
f010451c:	76 1f                	jbe    f010453d <print_trapframe+0x72>
		return "System call";
f010451e:	ba 75 81 10 f0       	mov    $0xf0108175,%edx
	if (trapno == T_SYSCALL)
f0104523:	83 f8 30             	cmp    $0x30,%eax
f0104526:	74 1c                	je     f0104544 <print_trapframe+0x79>
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104528:	8d 50 e0             	lea    -0x20(%eax),%edx
	return "(unknown trap)";
f010452b:	83 fa 10             	cmp    $0x10,%edx
f010452e:	ba 81 81 10 f0       	mov    $0xf0108181,%edx
f0104533:	b9 94 81 10 f0       	mov    $0xf0108194,%ecx
f0104538:	0f 43 d1             	cmovae %ecx,%edx
f010453b:	eb 07                	jmp    f0104544 <print_trapframe+0x79>
		return excnames[trapno];
f010453d:	8b 14 85 a0 84 10 f0 	mov    -0xfef7b60(,%eax,4),%edx
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104544:	83 ec 04             	sub    $0x4,%esp
f0104547:	52                   	push   %edx
f0104548:	50                   	push   %eax
f0104549:	68 0e 82 10 f0       	push   $0xf010820e
f010454e:	e8 18 f8 ff ff       	call   f0103d6b <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104553:	83 c4 10             	add    $0x10,%esp
f0104556:	39 1d 60 6a 21 f0    	cmp    %ebx,0xf0216a60
f010455c:	0f 84 a6 00 00 00    	je     f0104608 <print_trapframe+0x13d>
	cprintf("  err  0x%08x", tf->tf_err);
f0104562:	83 ec 08             	sub    $0x8,%esp
f0104565:	ff 73 2c             	pushl  0x2c(%ebx)
f0104568:	68 2f 82 10 f0       	push   $0xf010822f
f010456d:	e8 f9 f7 ff ff       	call   f0103d6b <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104572:	83 c4 10             	add    $0x10,%esp
f0104575:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0104579:	0f 85 ac 00 00 00    	jne    f010462b <print_trapframe+0x160>
			tf->tf_err & 1 ? "protection" : "not-present");
f010457f:	8b 43 2c             	mov    0x2c(%ebx),%eax
		cprintf(" [%s, %s, %s]\n",
f0104582:	89 c2                	mov    %eax,%edx
f0104584:	83 e2 01             	and    $0x1,%edx
f0104587:	b9 a3 81 10 f0       	mov    $0xf01081a3,%ecx
f010458c:	ba ae 81 10 f0       	mov    $0xf01081ae,%edx
f0104591:	0f 44 ca             	cmove  %edx,%ecx
f0104594:	89 c2                	mov    %eax,%edx
f0104596:	83 e2 02             	and    $0x2,%edx
f0104599:	be ba 81 10 f0       	mov    $0xf01081ba,%esi
f010459e:	ba c0 81 10 f0       	mov    $0xf01081c0,%edx
f01045a3:	0f 45 d6             	cmovne %esi,%edx
f01045a6:	83 e0 04             	and    $0x4,%eax
f01045a9:	b8 c5 81 10 f0       	mov    $0xf01081c5,%eax
f01045ae:	be 2b 83 10 f0       	mov    $0xf010832b,%esi
f01045b3:	0f 44 c6             	cmove  %esi,%eax
f01045b6:	51                   	push   %ecx
f01045b7:	52                   	push   %edx
f01045b8:	50                   	push   %eax
f01045b9:	68 3d 82 10 f0       	push   $0xf010823d
f01045be:	e8 a8 f7 ff ff       	call   f0103d6b <cprintf>
f01045c3:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01045c6:	83 ec 08             	sub    $0x8,%esp
f01045c9:	ff 73 30             	pushl  0x30(%ebx)
f01045cc:	68 4c 82 10 f0       	push   $0xf010824c
f01045d1:	e8 95 f7 ff ff       	call   f0103d6b <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01045d6:	83 c4 08             	add    $0x8,%esp
f01045d9:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01045dd:	50                   	push   %eax
f01045de:	68 5b 82 10 f0       	push   $0xf010825b
f01045e3:	e8 83 f7 ff ff       	call   f0103d6b <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01045e8:	83 c4 08             	add    $0x8,%esp
f01045eb:	ff 73 38             	pushl  0x38(%ebx)
f01045ee:	68 6e 82 10 f0       	push   $0xf010826e
f01045f3:	e8 73 f7 ff ff       	call   f0103d6b <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01045f8:	83 c4 10             	add    $0x10,%esp
f01045fb:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01045ff:	75 3c                	jne    f010463d <print_trapframe+0x172>
}
f0104601:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104604:	5b                   	pop    %ebx
f0104605:	5e                   	pop    %esi
f0104606:	5d                   	pop    %ebp
f0104607:	c3                   	ret    
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104608:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010460c:	0f 85 50 ff ff ff    	jne    f0104562 <print_trapframe+0x97>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0104612:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104615:	83 ec 08             	sub    $0x8,%esp
f0104618:	50                   	push   %eax
f0104619:	68 20 82 10 f0       	push   $0xf0108220
f010461e:	e8 48 f7 ff ff       	call   f0103d6b <cprintf>
f0104623:	83 c4 10             	add    $0x10,%esp
f0104626:	e9 37 ff ff ff       	jmp    f0104562 <print_trapframe+0x97>
		cprintf("\n");
f010462b:	83 ec 0c             	sub    $0xc,%esp
f010462e:	68 4b 6e 10 f0       	push   $0xf0106e4b
f0104633:	e8 33 f7 ff ff       	call   f0103d6b <cprintf>
f0104638:	83 c4 10             	add    $0x10,%esp
f010463b:	eb 89                	jmp    f01045c6 <print_trapframe+0xfb>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010463d:	83 ec 08             	sub    $0x8,%esp
f0104640:	ff 73 3c             	pushl  0x3c(%ebx)
f0104643:	68 7d 82 10 f0       	push   $0xf010827d
f0104648:	e8 1e f7 ff ff       	call   f0103d6b <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010464d:	83 c4 08             	add    $0x8,%esp
f0104650:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104654:	50                   	push   %eax
f0104655:	68 8c 82 10 f0       	push   $0xf010828c
f010465a:	e8 0c f7 ff ff       	call   f0103d6b <cprintf>
f010465f:	83 c4 10             	add    $0x10,%esp
}
f0104662:	eb 9d                	jmp    f0104601 <print_trapframe+0x136>

f0104664 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104664:	55                   	push   %ebp
f0104665:	89 e5                	mov    %esp,%ebp
f0104667:	57                   	push   %edi
f0104668:	56                   	push   %esi
f0104669:	53                   	push   %ebx
f010466a:	83 ec 0c             	sub    $0xc,%esp
f010466d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104670:	0f 20 d6             	mov    %cr2,%esi

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.

	if ((tf -> tf_cs & 3) == 0)
f0104673:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104677:	75 17                	jne    f0104690 <page_fault_handler+0x2c>
		panic("page fault in kernel mode!");
f0104679:	83 ec 04             	sub    $0x4,%esp
f010467c:	68 9f 82 10 f0       	push   $0xf010829f
f0104681:	68 7b 01 00 00       	push   $0x17b
f0104686:	68 ba 82 10 f0       	push   $0xf01082ba
f010468b:	e8 b0 b9 ff ff       	call   f0100040 <_panic>
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	if (curenv->env_pgfault_upcall == NULL){
f0104690:	e8 0e 1e 00 00       	call   f01064a3 <cpunum>
f0104695:	6b c0 74             	imul   $0x74,%eax,%eax
f0104698:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f010469e:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f01046a2:	0f 84 9b 00 00 00    	je     f0104743 <page_fault_handler+0xdf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
		env_destroy(curenv);
	}

	uintptr_t esp = tf->tf_esp;
f01046a8:	8b 43 3c             	mov    0x3c(%ebx),%eax
	struct UTrapframe* utf = NULL;
	if (esp < USTACKTOP && esp >= USTACKTOP - PGSIZE)
f01046ab:	8d 90 00 30 40 11    	lea    0x11403000(%eax),%edx
f01046b1:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f01046b7:	0f 86 e3 00 00 00    	jbe    f01047a0 <page_fault_handler+0x13c>
		utf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	else if (esp < UXSTACKTOP && esp >= UXSTACKTOP - PGSIZE)
f01046bd:	8d 90 00 10 40 11    	lea    0x11401000(%eax),%edx
f01046c3:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f01046c9:	0f 87 ba 00 00 00    	ja     f0104789 <page_fault_handler+0x125>
		utf = (struct UTrapframe*)(esp - 4 - sizeof(struct UTrapframe));
f01046cf:	83 e8 38             	sub    $0x38,%eax
f01046d2:	89 c7                	mov    %eax,%edi
	else
		panic("unexpected trap frame");
	
	user_mem_assert(curenv, (void *)utf, sizeof(struct UTrapframe), PTE_U | PTE_W);
f01046d4:	e8 ca 1d 00 00       	call   f01064a3 <cpunum>
f01046d9:	6a 06                	push   $0x6
f01046db:	6a 34                	push   $0x34
f01046dd:	57                   	push   %edi
f01046de:	6b c0 74             	imul   $0x74,%eax,%eax
f01046e1:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f01046e7:	e8 53 ed ff ff       	call   f010343f <user_mem_assert>

	utf->utf_fault_va = fault_va;
f01046ec:	89 fa                	mov    %edi,%edx
f01046ee:	89 37                	mov    %esi,(%edi)
	utf->utf_err = tf->tf_err;
f01046f0:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01046f3:	89 47 04             	mov    %eax,0x4(%edi)
	utf->utf_regs = tf->tf_regs;
f01046f6:	8d 7f 08             	lea    0x8(%edi),%edi
f01046f9:	b9 08 00 00 00       	mov    $0x8,%ecx
f01046fe:	89 de                	mov    %ebx,%esi
f0104700:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	utf->utf_eip = tf->tf_eip;
f0104702:	8b 43 30             	mov    0x30(%ebx),%eax
f0104705:	89 d7                	mov    %edx,%edi
f0104707:	89 42 28             	mov    %eax,0x28(%edx)
	utf->utf_eflags = tf->tf_eflags;
f010470a:	8b 43 38             	mov    0x38(%ebx),%eax
f010470d:	89 42 2c             	mov    %eax,0x2c(%edx)
	utf->utf_esp = tf->tf_esp;
f0104710:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0104713:	89 42 30             	mov    %eax,0x30(%edx)
	
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
f0104716:	e8 88 1d 00 00       	call   f01064a3 <cpunum>
f010471b:	6b c0 74             	imul   $0x74,%eax,%eax
f010471e:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104724:	8b 40 64             	mov    0x64(%eax),%eax
f0104727:	89 43 30             	mov    %eax,0x30(%ebx)
	tf->tf_esp = (uintptr_t)utf;
f010472a:	89 7b 3c             	mov    %edi,0x3c(%ebx)
	env_run(curenv);
f010472d:	e8 71 1d 00 00       	call   f01064a3 <cpunum>
f0104732:	83 c4 04             	add    $0x4,%esp
f0104735:	6b c0 74             	imul   $0x74,%eax,%eax
f0104738:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f010473e:	e8 cb f3 ff ff       	call   f0103b0e <env_run>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104743:	8b 7b 30             	mov    0x30(%ebx),%edi
			curenv->env_id, fault_va, tf->tf_eip);
f0104746:	e8 58 1d 00 00       	call   f01064a3 <cpunum>
		cprintf("[%08x] user fault va %08x ip %08x\n",
f010474b:	57                   	push   %edi
f010474c:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f010474d:	6b c0 74             	imul   $0x74,%eax,%eax
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0104750:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104756:	ff 70 48             	pushl  0x48(%eax)
f0104759:	68 78 84 10 f0       	push   $0xf0108478
f010475e:	e8 08 f6 ff ff       	call   f0103d6b <cprintf>
		print_trapframe(tf);
f0104763:	89 1c 24             	mov    %ebx,(%esp)
f0104766:	e8 60 fd ff ff       	call   f01044cb <print_trapframe>
		env_destroy(curenv);
f010476b:	e8 33 1d 00 00       	call   f01064a3 <cpunum>
f0104770:	83 c4 04             	add    $0x4,%esp
f0104773:	6b c0 74             	imul   $0x74,%eax,%eax
f0104776:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f010477c:	e8 ee f2 ff ff       	call   f0103a6f <env_destroy>
f0104781:	83 c4 10             	add    $0x10,%esp
f0104784:	e9 1f ff ff ff       	jmp    f01046a8 <page_fault_handler+0x44>
		panic("unexpected trap frame");
f0104789:	83 ec 04             	sub    $0x4,%esp
f010478c:	68 c6 82 10 f0       	push   $0xf01082c6
f0104791:	68 ad 01 00 00       	push   $0x1ad
f0104796:	68 ba 82 10 f0       	push   $0xf01082ba
f010479b:	e8 a0 b8 ff ff       	call   f0100040 <_panic>
		utf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
f01047a0:	bf cc ff bf ee       	mov    $0xeebfffcc,%edi
f01047a5:	e9 2a ff ff ff       	jmp    f01046d4 <page_fault_handler+0x70>

f01047aa <trap>:
{
f01047aa:	55                   	push   %ebp
f01047ab:	89 e5                	mov    %esp,%ebp
f01047ad:	57                   	push   %edi
f01047ae:	56                   	push   %esi
f01047af:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f01047b2:	fc                   	cld    
	if (panicstr)
f01047b3:	83 3d 80 6e 21 f0 00 	cmpl   $0x0,0xf0216e80
f01047ba:	74 01                	je     f01047bd <trap+0x13>
		asm volatile("hlt");
f01047bc:	f4                   	hlt    
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f01047bd:	e8 e1 1c 00 00       	call   f01064a3 <cpunum>
f01047c2:	6b d0 74             	imul   $0x74,%eax,%edx
f01047c5:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f01047c8:	b8 01 00 00 00       	mov    $0x1,%eax
f01047cd:	f0 87 82 20 70 21 f0 	lock xchg %eax,-0xfde8fe0(%edx)
f01047d4:	83 f8 02             	cmp    $0x2,%eax
f01047d7:	0f 84 99 00 00 00    	je     f0104876 <trap+0xcc>
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01047dd:	9c                   	pushf  
f01047de:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01047df:	f6 c4 02             	test   $0x2,%ah
f01047e2:	0f 85 a3 00 00 00    	jne    f010488b <trap+0xe1>
	if ((tf->tf_cs & 3) == 3) {
f01047e8:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01047ec:	83 e0 03             	and    $0x3,%eax
f01047ef:	66 83 f8 03          	cmp    $0x3,%ax
f01047f3:	0f 84 ab 00 00 00    	je     f01048a4 <trap+0xfa>
	last_tf = tf;
f01047f9:	89 35 60 6a 21 f0    	mov    %esi,0xf0216a60
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01047ff:	8b 46 28             	mov    0x28(%esi),%eax
f0104802:	83 f8 27             	cmp    $0x27,%eax
f0104805:	0f 84 3e 01 00 00    	je     f0104949 <trap+0x19f>
	if (tf->tf_trapno == IRQ_OFFSET + 0) {
f010480b:	83 f8 20             	cmp    $0x20,%eax
f010480e:	0f 84 4f 01 00 00    	je     f0104963 <trap+0x1b9>
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD){
f0104814:	83 f8 21             	cmp    $0x21,%eax
f0104817:	0f 84 50 01 00 00    	je     f010496d <trap+0x1c3>
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL){
f010481d:	83 f8 24             	cmp    $0x24,%eax
f0104820:	0f 84 4e 01 00 00    	je     f0104974 <trap+0x1ca>
	switch (tf -> tf_trapno){
f0104826:	83 f8 0e             	cmp    $0xe,%eax
f0104829:	0f 84 4c 01 00 00    	je     f010497b <trap+0x1d1>
f010482f:	83 f8 30             	cmp    $0x30,%eax
f0104832:	0f 84 82 01 00 00    	je     f01049ba <trap+0x210>
f0104838:	83 f8 03             	cmp    $0x3,%eax
f010483b:	0f 84 43 01 00 00    	je     f0104984 <trap+0x1da>
	print_trapframe(tf);
f0104841:	83 ec 0c             	sub    $0xc,%esp
f0104844:	56                   	push   %esi
f0104845:	e8 81 fc ff ff       	call   f01044cb <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010484a:	83 c4 10             	add    $0x10,%esp
f010484d:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104852:	0f 84 83 01 00 00    	je     f01049db <trap+0x231>
		env_destroy(curenv);
f0104858:	e8 46 1c 00 00       	call   f01064a3 <cpunum>
f010485d:	83 ec 0c             	sub    $0xc,%esp
f0104860:	6b c0 74             	imul   $0x74,%eax,%eax
f0104863:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0104869:	e8 01 f2 ff ff       	call   f0103a6f <env_destroy>
f010486e:	83 c4 10             	add    $0x10,%esp
f0104871:	e9 1a 01 00 00       	jmp    f0104990 <trap+0x1e6>
	spin_lock(&kernel_lock);
f0104876:	83 ec 0c             	sub    $0xc,%esp
f0104879:	68 c0 33 12 f0       	push   $0xf01233c0
f010487e:	e8 90 1e 00 00       	call   f0106713 <spin_lock>
f0104883:	83 c4 10             	add    $0x10,%esp
f0104886:	e9 52 ff ff ff       	jmp    f01047dd <trap+0x33>
	assert(!(read_eflags() & FL_IF));
f010488b:	68 dc 82 10 f0       	push   $0xf01082dc
f0104890:	68 ba 73 10 f0       	push   $0xf01073ba
f0104895:	68 44 01 00 00       	push   $0x144
f010489a:	68 ba 82 10 f0       	push   $0xf01082ba
f010489f:	e8 9c b7 ff ff       	call   f0100040 <_panic>
f01048a4:	83 ec 0c             	sub    $0xc,%esp
f01048a7:	68 c0 33 12 f0       	push   $0xf01233c0
f01048ac:	e8 62 1e 00 00       	call   f0106713 <spin_lock>
		assert(curenv);
f01048b1:	e8 ed 1b 00 00       	call   f01064a3 <cpunum>
f01048b6:	6b c0 74             	imul   $0x74,%eax,%eax
f01048b9:	83 c4 10             	add    $0x10,%esp
f01048bc:	83 b8 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%eax)
f01048c3:	74 3e                	je     f0104903 <trap+0x159>
		if (curenv->env_status == ENV_DYING) {
f01048c5:	e8 d9 1b 00 00       	call   f01064a3 <cpunum>
f01048ca:	6b c0 74             	imul   $0x74,%eax,%eax
f01048cd:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f01048d3:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01048d7:	74 43                	je     f010491c <trap+0x172>
		curenv->env_tf = *tf;
f01048d9:	e8 c5 1b 00 00       	call   f01064a3 <cpunum>
f01048de:	6b c0 74             	imul   $0x74,%eax,%eax
f01048e1:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f01048e7:	b9 11 00 00 00       	mov    $0x11,%ecx
f01048ec:	89 c7                	mov    %eax,%edi
f01048ee:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f01048f0:	e8 ae 1b 00 00       	call   f01064a3 <cpunum>
f01048f5:	6b c0 74             	imul   $0x74,%eax,%eax
f01048f8:	8b b0 28 70 21 f0    	mov    -0xfde8fd8(%eax),%esi
f01048fe:	e9 f6 fe ff ff       	jmp    f01047f9 <trap+0x4f>
		assert(curenv);
f0104903:	68 f5 82 10 f0       	push   $0xf01082f5
f0104908:	68 ba 73 10 f0       	push   $0xf01073ba
f010490d:	68 4c 01 00 00       	push   $0x14c
f0104912:	68 ba 82 10 f0       	push   $0xf01082ba
f0104917:	e8 24 b7 ff ff       	call   f0100040 <_panic>
			env_free(curenv);
f010491c:	e8 82 1b 00 00       	call   f01064a3 <cpunum>
f0104921:	83 ec 0c             	sub    $0xc,%esp
f0104924:	6b c0 74             	imul   $0x74,%eax,%eax
f0104927:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f010492d:	e8 80 ef ff ff       	call   f01038b2 <env_free>
			curenv = NULL;
f0104932:	e8 6c 1b 00 00       	call   f01064a3 <cpunum>
f0104937:	6b c0 74             	imul   $0x74,%eax,%eax
f010493a:	c7 80 28 70 21 f0 00 	movl   $0x0,-0xfde8fd8(%eax)
f0104941:	00 00 00 
			sched_yield();
f0104944:	e8 ac 02 00 00       	call   f0104bf5 <sched_yield>
		cprintf("Spurious interrupt on irq 7\n");
f0104949:	83 ec 0c             	sub    $0xc,%esp
f010494c:	68 fc 82 10 f0       	push   $0xf01082fc
f0104951:	e8 15 f4 ff ff       	call   f0103d6b <cprintf>
		print_trapframe(tf);
f0104956:	89 34 24             	mov    %esi,(%esp)
f0104959:	e8 6d fb ff ff       	call   f01044cb <print_trapframe>
f010495e:	83 c4 10             	add    $0x10,%esp
f0104961:	eb 2d                	jmp    f0104990 <trap+0x1e6>
		lapic_eoi();
f0104963:	e8 87 1c 00 00       	call   f01065ef <lapic_eoi>
		sched_yield();
f0104968:	e8 88 02 00 00       	call   f0104bf5 <sched_yield>
		kbd_intr();
f010496d:	e8 89 bc ff ff       	call   f01005fb <kbd_intr>
f0104972:	eb 1c                	jmp    f0104990 <trap+0x1e6>
		serial_intr();
f0104974:	e8 65 bc ff ff       	call   f01005de <serial_intr>
f0104979:	eb 15                	jmp    f0104990 <trap+0x1e6>
			page_fault_handler(tf);
f010497b:	83 ec 0c             	sub    $0xc,%esp
f010497e:	56                   	push   %esi
f010497f:	e8 e0 fc ff ff       	call   f0104664 <page_fault_handler>
			monitor(tf);
f0104984:	83 ec 0c             	sub    $0xc,%esp
f0104987:	56                   	push   %esi
f0104988:	e8 ff c3 ff ff       	call   f0100d8c <monitor>
f010498d:	83 c4 10             	add    $0x10,%esp
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104990:	e8 0e 1b 00 00       	call   f01064a3 <cpunum>
f0104995:	6b c0 74             	imul   $0x74,%eax,%eax
f0104998:	83 b8 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%eax)
f010499f:	74 14                	je     f01049b5 <trap+0x20b>
f01049a1:	e8 fd 1a 00 00       	call   f01064a3 <cpunum>
f01049a6:	6b c0 74             	imul   $0x74,%eax,%eax
f01049a9:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f01049af:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01049b3:	74 3d                	je     f01049f2 <trap+0x248>
		sched_yield();
f01049b5:	e8 3b 02 00 00       	call   f0104bf5 <sched_yield>
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f01049ba:	83 ec 08             	sub    $0x8,%esp
f01049bd:	ff 76 04             	pushl  0x4(%esi)
f01049c0:	ff 36                	pushl  (%esi)
f01049c2:	ff 76 10             	pushl  0x10(%esi)
f01049c5:	ff 76 18             	pushl  0x18(%esi)
f01049c8:	ff 76 14             	pushl  0x14(%esi)
f01049cb:	ff 76 1c             	pushl  0x1c(%esi)
f01049ce:	e8 e9 02 00 00       	call   f0104cbc <syscall>
f01049d3:	89 46 1c             	mov    %eax,0x1c(%esi)
f01049d6:	83 c4 20             	add    $0x20,%esp
f01049d9:	eb b5                	jmp    f0104990 <trap+0x1e6>
		panic("unhandled trap in kernel");
f01049db:	83 ec 04             	sub    $0x4,%esp
f01049de:	68 19 83 10 f0       	push   $0xf0108319
f01049e3:	68 2a 01 00 00       	push   $0x12a
f01049e8:	68 ba 82 10 f0       	push   $0xf01082ba
f01049ed:	e8 4e b6 ff ff       	call   f0100040 <_panic>
		env_run(curenv);
f01049f2:	e8 ac 1a 00 00       	call   f01064a3 <cpunum>
f01049f7:	83 ec 0c             	sub    $0xc,%esp
f01049fa:	6b c0 74             	imul   $0x74,%eax,%eax
f01049fd:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0104a03:	e8 06 f1 ff ff       	call   f0103b0e <env_run>

f0104a08 <T_DBLFLT_H>:

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */

TRAPHANDLER(T_DBLFLT_H, T_DBLFLT)
f0104a08:	6a 08                	push   $0x8
f0104a0a:	e9 03 01 00 00       	jmp    f0104b12 <_alltraps>
f0104a0f:	90                   	nop

f0104a10 <T_TSS_H>:
TRAPHANDLER(T_TSS_H, T_TSS)
f0104a10:	6a 0a                	push   $0xa
f0104a12:	e9 fb 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a17:	90                   	nop

f0104a18 <T_SEGNP_H>:
TRAPHANDLER(T_SEGNP_H, T_SEGNP)
f0104a18:	6a 0b                	push   $0xb
f0104a1a:	e9 f3 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a1f:	90                   	nop

f0104a20 <T_STACK_H>:
TRAPHANDLER(T_STACK_H, T_STACK)
f0104a20:	6a 0c                	push   $0xc
f0104a22:	e9 eb 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a27:	90                   	nop

f0104a28 <T_GPFLT_H>:
TRAPHANDLER(T_GPFLT_H, T_GPFLT)
f0104a28:	6a 0d                	push   $0xd
f0104a2a:	e9 e3 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a2f:	90                   	nop

f0104a30 <T_PGFLT_H>:
TRAPHANDLER(T_PGFLT_H, T_PGFLT)
f0104a30:	6a 0e                	push   $0xe
f0104a32:	e9 db 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a37:	90                   	nop

f0104a38 <T_ALIGN_H>:
TRAPHANDLER(T_ALIGN_H, T_ALIGN)
f0104a38:	6a 11                	push   $0x11
f0104a3a:	e9 d3 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a3f:	90                   	nop

f0104a40 <T_DIVIDE_H>:

TRAPHANDLER_NOEC(T_DIVIDE_H, T_DIVIDE)
f0104a40:	6a 00                	push   $0x0
f0104a42:	6a 00                	push   $0x0
f0104a44:	e9 c9 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a49:	90                   	nop

f0104a4a <T_DEBUG_H>:
TRAPHANDLER_NOEC(T_DEBUG_H, T_DEBUG)
f0104a4a:	6a 00                	push   $0x0
f0104a4c:	6a 01                	push   $0x1
f0104a4e:	e9 bf 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a53:	90                   	nop

f0104a54 <T_NMI_H>:
TRAPHANDLER_NOEC(T_NMI_H, T_NMI)
f0104a54:	6a 00                	push   $0x0
f0104a56:	6a 02                	push   $0x2
f0104a58:	e9 b5 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a5d:	90                   	nop

f0104a5e <T_BRKPT_H>:
TRAPHANDLER_NOEC(T_BRKPT_H, T_BRKPT)
f0104a5e:	6a 00                	push   $0x0
f0104a60:	6a 03                	push   $0x3
f0104a62:	e9 ab 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a67:	90                   	nop

f0104a68 <T_OFLOW_H>:
TRAPHANDLER_NOEC(T_OFLOW_H, T_OFLOW)
f0104a68:	6a 00                	push   $0x0
f0104a6a:	6a 04                	push   $0x4
f0104a6c:	e9 a1 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a71:	90                   	nop

f0104a72 <T_BOUND_H>:
TRAPHANDLER_NOEC(T_BOUND_H, T_BOUND)
f0104a72:	6a 00                	push   $0x0
f0104a74:	6a 05                	push   $0x5
f0104a76:	e9 97 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a7b:	90                   	nop

f0104a7c <T_DEVICE_H>:
TRAPHANDLER_NOEC(T_DEVICE_H, T_DEVICE)
f0104a7c:	6a 00                	push   $0x0
f0104a7e:	6a 07                	push   $0x7
f0104a80:	e9 8d 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a85:	90                   	nop

f0104a86 <T_ILLOP_H>:
TRAPHANDLER_NOEC(T_ILLOP_H, T_ILLOP)
f0104a86:	6a 00                	push   $0x0
f0104a88:	6a 06                	push   $0x6
f0104a8a:	e9 83 00 00 00       	jmp    f0104b12 <_alltraps>
f0104a8f:	90                   	nop

f0104a90 <T_FPERR_H>:
TRAPHANDLER_NOEC(T_FPERR_H, T_FPERR)
f0104a90:	6a 00                	push   $0x0
f0104a92:	6a 10                	push   $0x10
f0104a94:	eb 7c                	jmp    f0104b12 <_alltraps>

f0104a96 <T_MCHK_H>:
TRAPHANDLER_NOEC(T_MCHK_H, T_MCHK)
f0104a96:	6a 00                	push   $0x0
f0104a98:	6a 12                	push   $0x12
f0104a9a:	eb 76                	jmp    f0104b12 <_alltraps>

f0104a9c <T_SIMDERR_H>:
TRAPHANDLER_NOEC(T_SIMDERR_H, T_SIMDERR)
f0104a9c:	6a 00                	push   $0x0
f0104a9e:	6a 13                	push   $0x13
f0104aa0:	eb 70                	jmp    f0104b12 <_alltraps>

f0104aa2 <T_SYSCALL_H>:
TRAPHANDLER_NOEC(T_SYSCALL_H, T_SYSCALL)
f0104aa2:	6a 00                	push   $0x0
f0104aa4:	6a 30                	push   $0x30
f0104aa6:	eb 6a                	jmp    f0104b12 <_alltraps>

f0104aa8 <T_DEFAULT_H>:
TRAPHANDLER_NOEC(T_DEFAULT_H, T_DEFAULT)
f0104aa8:	6a 00                	push   $0x0
f0104aaa:	68 f4 01 00 00       	push   $0x1f4
f0104aaf:	eb 61                	jmp    f0104b12 <_alltraps>
f0104ab1:	90                   	nop

f0104ab2 <IRQ_0_H>:

TRAPHANDLER_NOEC(IRQ_0_H, IRQ_OFFSET + 0)
f0104ab2:	6a 00                	push   $0x0
f0104ab4:	6a 20                	push   $0x20
f0104ab6:	eb 5a                	jmp    f0104b12 <_alltraps>

f0104ab8 <IRQ_1_H>:
TRAPHANDLER_NOEC(IRQ_1_H, IRQ_OFFSET + 1)
f0104ab8:	6a 00                	push   $0x0
f0104aba:	6a 21                	push   $0x21
f0104abc:	eb 54                	jmp    f0104b12 <_alltraps>

f0104abe <IRQ_2_H>:
TRAPHANDLER_NOEC(IRQ_2_H, IRQ_OFFSET + 2)
f0104abe:	6a 00                	push   $0x0
f0104ac0:	6a 22                	push   $0x22
f0104ac2:	eb 4e                	jmp    f0104b12 <_alltraps>

f0104ac4 <IRQ_3_H>:
TRAPHANDLER_NOEC(IRQ_3_H, IRQ_OFFSET + 3)
f0104ac4:	6a 00                	push   $0x0
f0104ac6:	6a 23                	push   $0x23
f0104ac8:	eb 48                	jmp    f0104b12 <_alltraps>

f0104aca <IRQ_4_H>:
TRAPHANDLER_NOEC(IRQ_4_H, IRQ_OFFSET + 4)
f0104aca:	6a 00                	push   $0x0
f0104acc:	6a 24                	push   $0x24
f0104ace:	eb 42                	jmp    f0104b12 <_alltraps>

f0104ad0 <IRQ_5_H>:
TRAPHANDLER_NOEC(IRQ_5_H, IRQ_OFFSET + 5)
f0104ad0:	6a 00                	push   $0x0
f0104ad2:	6a 25                	push   $0x25
f0104ad4:	eb 3c                	jmp    f0104b12 <_alltraps>

f0104ad6 <IRQ_6_H>:
TRAPHANDLER_NOEC(IRQ_6_H, IRQ_OFFSET + 6)
f0104ad6:	6a 00                	push   $0x0
f0104ad8:	6a 26                	push   $0x26
f0104ada:	eb 36                	jmp    f0104b12 <_alltraps>

f0104adc <IRQ_7_H>:
TRAPHANDLER_NOEC(IRQ_7_H, IRQ_OFFSET + 7)
f0104adc:	6a 00                	push   $0x0
f0104ade:	6a 27                	push   $0x27
f0104ae0:	eb 30                	jmp    f0104b12 <_alltraps>

f0104ae2 <IRQ_8_H>:
TRAPHANDLER_NOEC(IRQ_8_H, IRQ_OFFSET + 8)
f0104ae2:	6a 00                	push   $0x0
f0104ae4:	6a 28                	push   $0x28
f0104ae6:	eb 2a                	jmp    f0104b12 <_alltraps>

f0104ae8 <IRQ_9_H>:
TRAPHANDLER_NOEC(IRQ_9_H, IRQ_OFFSET + 9)
f0104ae8:	6a 00                	push   $0x0
f0104aea:	6a 29                	push   $0x29
f0104aec:	eb 24                	jmp    f0104b12 <_alltraps>

f0104aee <IRQ_10_H>:
TRAPHANDLER_NOEC(IRQ_10_H, IRQ_OFFSET + 10)
f0104aee:	6a 00                	push   $0x0
f0104af0:	6a 2a                	push   $0x2a
f0104af2:	eb 1e                	jmp    f0104b12 <_alltraps>

f0104af4 <IRQ_11_H>:
TRAPHANDLER_NOEC(IRQ_11_H, IRQ_OFFSET + 11)
f0104af4:	6a 00                	push   $0x0
f0104af6:	6a 2b                	push   $0x2b
f0104af8:	eb 18                	jmp    f0104b12 <_alltraps>

f0104afa <IRQ_12_H>:
TRAPHANDLER_NOEC(IRQ_12_H, IRQ_OFFSET + 12)
f0104afa:	6a 00                	push   $0x0
f0104afc:	6a 2c                	push   $0x2c
f0104afe:	eb 12                	jmp    f0104b12 <_alltraps>

f0104b00 <IRQ_13_H>:
TRAPHANDLER_NOEC(IRQ_13_H, IRQ_OFFSET + 13)
f0104b00:	6a 00                	push   $0x0
f0104b02:	6a 2d                	push   $0x2d
f0104b04:	eb 0c                	jmp    f0104b12 <_alltraps>

f0104b06 <IRQ_14_H>:
TRAPHANDLER_NOEC(IRQ_14_H, IRQ_OFFSET + 14)
f0104b06:	6a 00                	push   $0x0
f0104b08:	6a 2e                	push   $0x2e
f0104b0a:	eb 06                	jmp    f0104b12 <_alltraps>

f0104b0c <IRQ_15_H>:
TRAPHANDLER_NOEC(IRQ_15_H, IRQ_OFFSET + 15)
f0104b0c:	6a 00                	push   $0x0
f0104b0e:	6a 2f                	push   $0x2f
f0104b10:	eb 00                	jmp    f0104b12 <_alltraps>

f0104b12 <_alltraps>:
 * Lab 3: Your code here for _alltraps
 */

_alltraps:

	pushl %ds
f0104b12:	1e                   	push   %ds
	pushl %es
f0104b13:	06                   	push   %es
	pushal    # push all registers
f0104b14:	60                   	pusha  

	movw $GD_KD, %ax
f0104b15:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104b19:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104b1b:	8e c0                	mov    %eax,%es

	pushl %esp
f0104b1d:	54                   	push   %esp
f0104b1e:	e8 87 fc ff ff       	call   f01047aa <trap>

f0104b23 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104b23:	55                   	push   %ebp
f0104b24:	89 e5                	mov    %esp,%ebp
f0104b26:	83 ec 08             	sub    $0x8,%esp
f0104b29:	a1 44 62 21 f0       	mov    0xf0216244,%eax
f0104b2e:	83 c0 54             	add    $0x54,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104b31:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104b36:	8b 10                	mov    (%eax),%edx
f0104b38:	83 ea 01             	sub    $0x1,%edx
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104b3b:	83 fa 02             	cmp    $0x2,%edx
f0104b3e:	76 2d                	jbe    f0104b6d <sched_halt+0x4a>
	for (i = 0; i < NENV; i++) {
f0104b40:	83 c1 01             	add    $0x1,%ecx
f0104b43:	83 c0 7c             	add    $0x7c,%eax
f0104b46:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104b4c:	75 e8                	jne    f0104b36 <sched_halt+0x13>
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
		cprintf("No runnable environments in the system!\n");
f0104b4e:	83 ec 0c             	sub    $0xc,%esp
f0104b51:	68 f0 84 10 f0       	push   $0xf01084f0
f0104b56:	e8 10 f2 ff ff       	call   f0103d6b <cprintf>
f0104b5b:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104b5e:	83 ec 0c             	sub    $0xc,%esp
f0104b61:	6a 00                	push   $0x0
f0104b63:	e8 24 c2 ff ff       	call   f0100d8c <monitor>
f0104b68:	83 c4 10             	add    $0x10,%esp
f0104b6b:	eb f1                	jmp    f0104b5e <sched_halt+0x3b>
	if (i == NENV) {
f0104b6d:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0104b73:	74 d9                	je     f0104b4e <sched_halt+0x2b>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104b75:	e8 29 19 00 00       	call   f01064a3 <cpunum>
f0104b7a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b7d:	c7 80 28 70 21 f0 00 	movl   $0x0,-0xfde8fd8(%eax)
f0104b84:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104b87:	a1 8c 6e 21 f0       	mov    0xf0216e8c,%eax
	if ((uint32_t)kva < KERNBASE)
f0104b8c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104b91:	76 50                	jbe    f0104be3 <sched_halt+0xc0>
	return (physaddr_t)kva - KERNBASE;
f0104b93:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0104b98:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104b9b:	e8 03 19 00 00       	call   f01064a3 <cpunum>
f0104ba0:	6b d0 74             	imul   $0x74,%eax,%edx
f0104ba3:	83 c2 04             	add    $0x4,%edx
	asm volatile("lock; xchgl %0, %1"
f0104ba6:	b8 02 00 00 00       	mov    $0x2,%eax
f0104bab:	f0 87 82 20 70 21 f0 	lock xchg %eax,-0xfde8fe0(%edx)
	spin_unlock(&kernel_lock);
f0104bb2:	83 ec 0c             	sub    $0xc,%esp
f0104bb5:	68 c0 33 12 f0       	push   $0xf01233c0
f0104bba:	e8 f1 1b 00 00       	call   f01067b0 <spin_unlock>
	asm volatile("pause");
f0104bbf:	f3 90                	pause  
		// Uncomment the following line after completing exercise 13
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104bc1:	e8 dd 18 00 00       	call   f01064a3 <cpunum>
f0104bc6:	6b c0 74             	imul   $0x74,%eax,%eax
	asm volatile (
f0104bc9:	8b 80 30 70 21 f0    	mov    -0xfde8fd0(%eax),%eax
f0104bcf:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104bd4:	89 c4                	mov    %eax,%esp
f0104bd6:	6a 00                	push   $0x0
f0104bd8:	6a 00                	push   $0x0
f0104bda:	fb                   	sti    
f0104bdb:	f4                   	hlt    
f0104bdc:	eb fd                	jmp    f0104bdb <sched_halt+0xb8>
}
f0104bde:	83 c4 10             	add    $0x10,%esp
f0104be1:	c9                   	leave  
f0104be2:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104be3:	50                   	push   %eax
f0104be4:	68 28 6b 10 f0       	push   $0xf0106b28
f0104be9:	6a 4c                	push   $0x4c
f0104beb:	68 19 85 10 f0       	push   $0xf0108519
f0104bf0:	e8 4b b4 ff ff       	call   f0100040 <_panic>

f0104bf5 <sched_yield>:
{
f0104bf5:	55                   	push   %ebp
f0104bf6:	89 e5                	mov    %esp,%ebp
f0104bf8:	53                   	push   %ebx
f0104bf9:	83 ec 04             	sub    $0x4,%esp
	if (curenv == NULL)
f0104bfc:	e8 a2 18 00 00       	call   f01064a3 <cpunum>
f0104c01:	6b d0 74             	imul   $0x74,%eax,%edx
		index = 0;
f0104c04:	b8 00 00 00 00       	mov    $0x0,%eax
	if (curenv == NULL)
f0104c09:	83 ba 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%edx)
f0104c10:	74 2d                	je     f0104c3f <sched_yield+0x4a>
		index = (curenv - envs + 1) % NENV;
f0104c12:	e8 8c 18 00 00       	call   f01064a3 <cpunum>
f0104c17:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c1a:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104c20:	2b 05 44 62 21 f0    	sub    0xf0216244,%eax
f0104c26:	c1 f8 02             	sar    $0x2,%eax
f0104c29:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f0104c2f:	83 c0 01             	add    $0x1,%eax
f0104c32:	99                   	cltd   
f0104c33:	c1 ea 16             	shr    $0x16,%edx
f0104c36:	01 d0                	add    %edx,%eax
f0104c38:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104c3d:	29 d0                	sub    %edx,%eax
		if (envs[index].env_status == ENV_RUNNABLE)
f0104c3f:	8b 0d 44 62 21 f0    	mov    0xf0216244,%ecx
f0104c45:	ba 00 04 00 00       	mov    $0x400,%edx
f0104c4a:	6b d8 7c             	imul   $0x7c,%eax,%ebx
f0104c4d:	01 cb                	add    %ecx,%ebx
f0104c4f:	83 7b 54 02          	cmpl   $0x2,0x54(%ebx)
f0104c53:	74 48                	je     f0104c9d <sched_yield+0xa8>
		index = (index + 1) % NENV;
f0104c55:	83 c0 01             	add    $0x1,%eax
f0104c58:	89 c3                	mov    %eax,%ebx
f0104c5a:	c1 fb 1f             	sar    $0x1f,%ebx
f0104c5d:	c1 eb 16             	shr    $0x16,%ebx
f0104c60:	01 d8                	add    %ebx,%eax
f0104c62:	25 ff 03 00 00       	and    $0x3ff,%eax
f0104c67:	29 d8                	sub    %ebx,%eax
	for (int i = 0; i < NENV; i++){
f0104c69:	83 ea 01             	sub    $0x1,%edx
f0104c6c:	75 dc                	jne    f0104c4a <sched_yield+0x55>
	if (curenv != NULL)
f0104c6e:	e8 30 18 00 00       	call   f01064a3 <cpunum>
f0104c73:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c76:	83 b8 28 70 21 f0 00 	cmpl   $0x0,-0xfde8fd8(%eax)
f0104c7d:	74 14                	je     f0104c93 <sched_yield+0x9e>
		if (curenv->env_status == ENV_RUNNING)
f0104c7f:	e8 1f 18 00 00       	call   f01064a3 <cpunum>
f0104c84:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c87:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104c8d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104c91:	74 13                	je     f0104ca6 <sched_yield+0xb1>
	sched_halt();
f0104c93:	e8 8b fe ff ff       	call   f0104b23 <sched_halt>
}
f0104c98:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104c9b:	c9                   	leave  
f0104c9c:	c3                   	ret    
			env_run(&envs[index]);
f0104c9d:	83 ec 0c             	sub    $0xc,%esp
f0104ca0:	53                   	push   %ebx
f0104ca1:	e8 68 ee ff ff       	call   f0103b0e <env_run>
			env_run(curenv);
f0104ca6:	e8 f8 17 00 00       	call   f01064a3 <cpunum>
f0104cab:	83 ec 0c             	sub    $0xc,%esp
f0104cae:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cb1:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0104cb7:	e8 52 ee ff ff       	call   f0103b0e <env_run>

f0104cbc <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104cbc:	55                   	push   %ebp
f0104cbd:	89 e5                	mov    %esp,%ebp
f0104cbf:	57                   	push   %edi
f0104cc0:	56                   	push   %esi
f0104cc1:	83 ec 10             	sub    $0x10,%esp
f0104cc4:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//panic("syscall not implemented");

	switch (syscallno) {
f0104cc7:	83 f8 0d             	cmp    $0xd,%eax
f0104cca:	0f 87 79 05 00 00    	ja     f0105249 <syscall+0x58d>
f0104cd0:	ff 24 85 2c 85 10 f0 	jmp    *-0xfef7ad4(,%eax,4)
	user_mem_assert(curenv, (void*) s, len, PTE_U);
f0104cd7:	e8 c7 17 00 00       	call   f01064a3 <cpunum>
f0104cdc:	6a 04                	push   $0x4
f0104cde:	ff 75 10             	pushl  0x10(%ebp)
f0104ce1:	ff 75 0c             	pushl  0xc(%ebp)
f0104ce4:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ce7:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0104ced:	e8 4d e7 ff ff       	call   f010343f <user_mem_assert>
	cprintf("%.*s", len, s);
f0104cf2:	83 c4 0c             	add    $0xc,%esp
f0104cf5:	ff 75 0c             	pushl  0xc(%ebp)
f0104cf8:	ff 75 10             	pushl  0x10(%ebp)
f0104cfb:	68 26 85 10 f0       	push   $0xf0108526
f0104d00:	e8 66 f0 ff ff       	call   f0103d6b <cprintf>
f0104d05:	83 c4 10             	add    $0x10,%esp
	case SYS_cputs:
		sys_cputs((const char*) a1, (size_t) a2);
		return 0;
f0104d08:	b8 00 00 00 00       	mov    $0x0,%eax
	case SYS_env_set_trapframe:
		return sys_env_set_trapframe((envid_t)a1, (struct Trapframe*)a2);
	default:
		return -E_INVAL;
	}
}
f0104d0d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0104d10:	5e                   	pop    %esi
f0104d11:	5f                   	pop    %edi
f0104d12:	5d                   	pop    %ebp
f0104d13:	c3                   	ret    
	return cons_getc();
f0104d14:	e8 f4 b8 ff ff       	call   f010060d <cons_getc>
		return sys_cgetc();
f0104d19:	eb f2                	jmp    f0104d0d <syscall+0x51>
	return curenv->env_id;
f0104d1b:	e8 83 17 00 00       	call   f01064a3 <cpunum>
f0104d20:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d23:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104d29:	8b 40 48             	mov    0x48(%eax),%eax
		return sys_getenvid();
f0104d2c:	eb df                	jmp    f0104d0d <syscall+0x51>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104d2e:	83 ec 04             	sub    $0x4,%esp
f0104d31:	6a 01                	push   $0x1
f0104d33:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104d36:	50                   	push   %eax
f0104d37:	ff 75 0c             	pushl  0xc(%ebp)
f0104d3a:	e8 d2 e7 ff ff       	call   f0103511 <envid2env>
f0104d3f:	83 c4 10             	add    $0x10,%esp
f0104d42:	85 c0                	test   %eax,%eax
f0104d44:	78 c7                	js     f0104d0d <syscall+0x51>
	env_destroy(e);
f0104d46:	83 ec 0c             	sub    $0xc,%esp
f0104d49:	ff 75 f4             	pushl  -0xc(%ebp)
f0104d4c:	e8 1e ed ff ff       	call   f0103a6f <env_destroy>
f0104d51:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104d54:	b8 00 00 00 00       	mov    $0x0,%eax
		return sys_env_destroy((envid_t)a1);
f0104d59:	eb b2                	jmp    f0104d0d <syscall+0x51>
	sched_yield();
f0104d5b:	e8 95 fe ff ff       	call   f0104bf5 <sched_yield>
	int result = env_alloc(&new_env, curenv->env_id);
f0104d60:	e8 3e 17 00 00       	call   f01064a3 <cpunum>
f0104d65:	83 ec 08             	sub    $0x8,%esp
f0104d68:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d6b:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0104d71:	ff 70 48             	pushl  0x48(%eax)
f0104d74:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104d77:	50                   	push   %eax
f0104d78:	e8 9e e8 ff ff       	call   f010361b <env_alloc>
	if (result < 0) return result;
f0104d7d:	83 c4 10             	add    $0x10,%esp
f0104d80:	85 c0                	test   %eax,%eax
f0104d82:	78 89                	js     f0104d0d <syscall+0x51>
	new_env->env_status = ENV_NOT_RUNNABLE;
f0104d84:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104d87:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	new_env->env_tf = curenv->env_tf;
f0104d8e:	e8 10 17 00 00       	call   f01064a3 <cpunum>
f0104d93:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d96:	8b b0 28 70 21 f0    	mov    -0xfde8fd8(%eax),%esi
f0104d9c:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104da1:	8b 7d f4             	mov    -0xc(%ebp),%edi
f0104da4:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	new_env->env_tf.tf_regs.reg_eax = 0;
f0104da6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104da9:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	return new_env->env_id;
f0104db0:	8b 40 48             	mov    0x48(%eax),%eax
		return sys_exofork();
f0104db3:	e9 55 ff ff ff       	jmp    f0104d0d <syscall+0x51>
		status != ENV_RUNNABLE)
f0104db8:	8b 45 10             	mov    0x10(%ebp),%eax
f0104dbb:	83 e8 02             	sub    $0x2,%eax
	if (status != ENV_NOT_RUNNABLE && 
f0104dbe:	a9 fd ff ff ff       	test   $0xfffffffd,%eax
f0104dc3:	75 2b                	jne    f0104df0 <syscall+0x134>
	int result = envid2env(envid, &env, 1);
f0104dc5:	83 ec 04             	sub    $0x4,%esp
f0104dc8:	6a 01                	push   $0x1
f0104dca:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104dcd:	50                   	push   %eax
f0104dce:	ff 75 0c             	pushl  0xc(%ebp)
f0104dd1:	e8 3b e7 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f0104dd6:	83 c4 10             	add    $0x10,%esp
f0104dd9:	85 c0                	test   %eax,%eax
f0104ddb:	78 1d                	js     f0104dfa <syscall+0x13e>
	env->env_status = status;
f0104ddd:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104de0:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104de3:	89 48 54             	mov    %ecx,0x54(%eax)
	return 0;
f0104de6:	b8 00 00 00 00       	mov    $0x0,%eax
f0104deb:	e9 1d ff ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104df0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104df5:	e9 13 ff ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f0104dfa:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		return sys_env_set_status((envid_t)a1, (int)a2);
f0104dff:	e9 09 ff ff ff       	jmp    f0104d0d <syscall+0x51>
	int result = envid2env(envid, &env, 1);
f0104e04:	83 ec 04             	sub    $0x4,%esp
f0104e07:	6a 01                	push   $0x1
f0104e09:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104e0c:	50                   	push   %eax
f0104e0d:	ff 75 0c             	pushl  0xc(%ebp)
f0104e10:	e8 fc e6 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f0104e15:	83 c4 10             	add    $0x10,%esp
f0104e18:	85 c0                	test   %eax,%eax
f0104e1a:	78 78                	js     f0104e94 <syscall+0x1d8>
	if (((uintptr_t)va >= UTOP) || 
f0104e1c:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104e23:	77 79                	ja     f0104e9e <syscall+0x1e2>
f0104e25:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104e2c:	75 7a                	jne    f0104ea8 <syscall+0x1ec>
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f0104e2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e31:	83 e0 05             	and    $0x5,%eax
f0104e34:	83 f8 05             	cmp    $0x5,%eax
f0104e37:	75 79                	jne    f0104eb2 <syscall+0x1f6>
		(perm | (PTE_AVAIL | PTE_W)) != (PTE_U | PTE_P | PTE_AVAIL | PTE_W))
f0104e39:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e3c:	0d 02 0e 00 00       	or     $0xe02,%eax
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f0104e41:	3d 07 0e 00 00       	cmp    $0xe07,%eax
f0104e46:	75 74                	jne    f0104ebc <syscall+0x200>
	struct PageInfo* pg = page_alloc(ALLOC_ZERO);
f0104e48:	83 ec 0c             	sub    $0xc,%esp
f0104e4b:	6a 01                	push   $0x1
f0104e4d:	e8 7c c5 ff ff       	call   f01013ce <page_alloc>
f0104e52:	89 c6                	mov    %eax,%esi
	if (pg == NULL)
f0104e54:	83 c4 10             	add    $0x10,%esp
f0104e57:	85 c0                	test   %eax,%eax
f0104e59:	74 6b                	je     f0104ec6 <syscall+0x20a>
	result = page_insert(env->env_pgdir, pg, va, perm);
f0104e5b:	ff 75 14             	pushl  0x14(%ebp)
f0104e5e:	ff 75 10             	pushl  0x10(%ebp)
f0104e61:	50                   	push   %eax
f0104e62:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e65:	ff 70 60             	pushl  0x60(%eax)
f0104e68:	e8 6e c8 ff ff       	call   f01016db <page_insert>
	if (result < 0){
f0104e6d:	83 c4 10             	add    $0x10,%esp
f0104e70:	85 c0                	test   %eax,%eax
f0104e72:	78 0a                	js     f0104e7e <syscall+0x1c2>
	return 0;
f0104e74:	b8 00 00 00 00       	mov    $0x0,%eax
		return sys_page_alloc((envid_t)a1, (void*)a2, (int)a3);
f0104e79:	e9 8f fe ff ff       	jmp    f0104d0d <syscall+0x51>
		page_free(pg);
f0104e7e:	83 ec 0c             	sub    $0xc,%esp
f0104e81:	56                   	push   %esi
f0104e82:	e8 b9 c5 ff ff       	call   f0101440 <page_free>
f0104e87:	83 c4 10             	add    $0x10,%esp
		return -E_NO_MEM;
f0104e8a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104e8f:	e9 79 fe ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f0104e94:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104e99:	e9 6f fe ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104e9e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104ea3:	e9 65 fe ff ff       	jmp    f0104d0d <syscall+0x51>
f0104ea8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104ead:	e9 5b fe ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104eb2:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104eb7:	e9 51 fe ff ff       	jmp    f0104d0d <syscall+0x51>
f0104ebc:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104ec1:	e9 47 fe ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_NO_MEM;
f0104ec6:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0104ecb:	e9 3d fe ff ff       	jmp    f0104d0d <syscall+0x51>
	result = envid2env(srcenvid, &srcenv, 1);
f0104ed0:	83 ec 04             	sub    $0x4,%esp
f0104ed3:	6a 01                	push   $0x1
f0104ed5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104ed8:	50                   	push   %eax
f0104ed9:	ff 75 0c             	pushl  0xc(%ebp)
f0104edc:	e8 30 e6 ff ff       	call   f0103511 <envid2env>
f0104ee1:	89 c6                	mov    %eax,%esi
	result |= envid2env(dstenvid, &dstenv, 1);
f0104ee3:	83 c4 0c             	add    $0xc,%esp
f0104ee6:	6a 01                	push   $0x1
f0104ee8:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0104eeb:	50                   	push   %eax
f0104eec:	ff 75 14             	pushl  0x14(%ebp)
f0104eef:	e8 1d e6 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f0104ef4:	83 c4 10             	add    $0x10,%esp
f0104ef7:	09 c6                	or     %eax,%esi
f0104ef9:	0f 88 89 00 00 00    	js     f0104f88 <syscall+0x2cc>
	if (((uintptr_t)srcva >= UTOP) ||
f0104eff:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104f06:	0f 87 86 00 00 00    	ja     f0104f92 <syscall+0x2d6>
f0104f0c:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f0104f13:	77 7d                	ja     f0104f92 <syscall+0x2d6>
		((uintptr_t)srcva % PGSIZE != 0) ||
f0104f15:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f18:	0b 45 18             	or     0x18(%ebp),%eax
f0104f1b:	a9 ff 0f 00 00       	test   $0xfff,%eax
f0104f20:	75 7a                	jne    f0104f9c <syscall+0x2e0>
	pg = page_lookup(srcenv->env_pgdir, srcva, &pte);
f0104f22:	83 ec 04             	sub    $0x4,%esp
f0104f25:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104f28:	50                   	push   %eax
f0104f29:	ff 75 10             	pushl  0x10(%ebp)
f0104f2c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104f2f:	ff 70 60             	pushl  0x60(%eax)
f0104f32:	e8 bc c6 ff ff       	call   f01015f3 <page_lookup>
	if (pg == NULL)
f0104f37:	83 c4 10             	add    $0x10,%esp
f0104f3a:	85 c0                	test   %eax,%eax
f0104f3c:	74 68                	je     f0104fa6 <syscall+0x2ea>
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f0104f3e:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104f41:	83 e2 05             	and    $0x5,%edx
f0104f44:	83 fa 05             	cmp    $0x5,%edx
f0104f47:	75 67                	jne    f0104fb0 <syscall+0x2f4>
		(perm | (PTE_AVAIL | PTE_W)) != (PTE_U | PTE_P | PTE_AVAIL | PTE_W))
f0104f49:	8b 55 1c             	mov    0x1c(%ebp),%edx
f0104f4c:	81 ca 02 0e 00 00    	or     $0xe02,%edx
	if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f0104f52:	81 fa 07 0e 00 00    	cmp    $0xe07,%edx
f0104f58:	75 60                	jne    f0104fba <syscall+0x2fe>
	if (((perm & PTE_W) == PTE_W))
f0104f5a:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f0104f5e:	74 08                	je     f0104f68 <syscall+0x2ac>
		if (((*pte & PTE_W) != PTE_W))
f0104f60:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104f63:	f6 02 02             	testb  $0x2,(%edx)
f0104f66:	74 5c                	je     f0104fc4 <syscall+0x308>
	result = page_insert(dstenv->env_pgdir, pg, dstva, perm);
f0104f68:	ff 75 1c             	pushl  0x1c(%ebp)
f0104f6b:	ff 75 18             	pushl  0x18(%ebp)
f0104f6e:	50                   	push   %eax
f0104f6f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104f72:	ff 70 60             	pushl  0x60(%eax)
f0104f75:	e8 61 c7 ff ff       	call   f01016db <page_insert>
	if (result < 0)
f0104f7a:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104f7d:	c1 e8 1f             	shr    $0x1f,%eax
f0104f80:	c1 e0 02             	shl    $0x2,%eax
f0104f83:	e9 85 fd ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f0104f88:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0104f8d:	e9 7b fd ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104f92:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104f97:	e9 71 fd ff ff       	jmp    f0104d0d <syscall+0x51>
f0104f9c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fa1:	e9 67 fd ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_INVAL;
f0104fa6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fab:	e9 5d fd ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104fb0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fb5:	e9 53 fd ff ff       	jmp    f0104d0d <syscall+0x51>
f0104fba:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fbf:	e9 49 fd ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0104fc4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104fc9:	e9 3f fd ff ff       	jmp    f0104d0d <syscall+0x51>
	int result = envid2env(envid, &env, 1);
f0104fce:	83 ec 04             	sub    $0x4,%esp
f0104fd1:	6a 01                	push   $0x1
f0104fd3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104fd6:	50                   	push   %eax
f0104fd7:	ff 75 0c             	pushl  0xc(%ebp)
f0104fda:	e8 32 e5 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f0104fdf:	83 c4 10             	add    $0x10,%esp
f0104fe2:	85 c0                	test   %eax,%eax
f0104fe4:	78 30                	js     f0105016 <syscall+0x35a>
	if (((uintptr_t)va >= UTOP) ||
f0104fe6:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104fed:	77 31                	ja     f0105020 <syscall+0x364>
f0104fef:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104ff6:	75 32                	jne    f010502a <syscall+0x36e>
	page_remove(env->env_pgdir, va);
f0104ff8:	83 ec 08             	sub    $0x8,%esp
f0104ffb:	ff 75 10             	pushl  0x10(%ebp)
f0104ffe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105001:	ff 70 60             	pushl  0x60(%eax)
f0105004:	e8 85 c6 ff ff       	call   f010168e <page_remove>
f0105009:	83 c4 10             	add    $0x10,%esp
	return 0;
f010500c:	b8 00 00 00 00       	mov    $0x0,%eax
f0105011:	e9 f7 fc ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f0105016:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010501b:	e9 ed fc ff ff       	jmp    f0104d0d <syscall+0x51>
			return -E_INVAL;
f0105020:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105025:	e9 e3 fc ff ff       	jmp    f0104d0d <syscall+0x51>
f010502a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		return sys_page_unmap((envid_t)a1, (void*)a2);
f010502f:	e9 d9 fc ff ff       	jmp    f0104d0d <syscall+0x51>
	int result = envid2env(envid, &env, 1);
f0105034:	83 ec 04             	sub    $0x4,%esp
f0105037:	6a 01                	push   $0x1
f0105039:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010503c:	50                   	push   %eax
f010503d:	ff 75 0c             	pushl  0xc(%ebp)
f0105040:	e8 cc e4 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f0105045:	83 c4 10             	add    $0x10,%esp
f0105048:	85 c0                	test   %eax,%eax
f010504a:	78 13                	js     f010505f <syscall+0x3a3>
	env->env_pgfault_upcall = func;
f010504c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010504f:	8b 7d 10             	mov    0x10(%ebp),%edi
f0105052:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f0105055:	b8 00 00 00 00       	mov    $0x0,%eax
f010505a:	e9 ae fc ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f010505f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		return sys_env_set_pgfault_upcall((envid_t)a1, (void*)a2);
f0105064:	e9 a4 fc ff ff       	jmp    f0104d0d <syscall+0x51>
	if (((uintptr_t) dstva < UTOP) &&
f0105069:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f0105070:	77 13                	ja     f0105085 <syscall+0x3c9>
f0105072:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0105079:	74 0a                	je     f0105085 <syscall+0x3c9>
		return sys_ipc_recv((void*)a1);
f010507b:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105080:	e9 88 fc ff ff       	jmp    f0104d0d <syscall+0x51>
	curenv->env_ipc_recving = true;
f0105085:	e8 19 14 00 00       	call   f01064a3 <cpunum>
f010508a:	6b c0 74             	imul   $0x74,%eax,%eax
f010508d:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0105093:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_ipc_dstva = dstva;
f0105097:	e8 07 14 00 00       	call   f01064a3 <cpunum>
f010509c:	6b c0 74             	imul   $0x74,%eax,%eax
f010509f:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f01050a5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01050a8:	89 48 6c             	mov    %ecx,0x6c(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f01050ab:	e8 f3 13 00 00       	call   f01064a3 <cpunum>
f01050b0:	6b c0 74             	imul   $0x74,%eax,%eax
f01050b3:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f01050b9:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f01050c0:	e8 30 fb ff ff       	call   f0104bf5 <sched_yield>
	int result = envid2env(envid, &env, 0);
f01050c5:	83 ec 04             	sub    $0x4,%esp
f01050c8:	6a 00                	push   $0x0
f01050ca:	8d 45 f0             	lea    -0x10(%ebp),%eax
f01050cd:	50                   	push   %eax
f01050ce:	ff 75 0c             	pushl  0xc(%ebp)
f01050d1:	e8 3b e4 ff ff       	call   f0103511 <envid2env>
	if (result < 0)
f01050d6:	83 c4 10             	add    $0x10,%esp
f01050d9:	85 c0                	test   %eax,%eax
f01050db:	0f 88 07 01 00 00    	js     f01051e8 <syscall+0x52c>
	if (!env->env_ipc_recving)
f01050e1:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01050e4:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f01050e8:	0f 84 04 01 00 00    	je     f01051f2 <syscall+0x536>
	if ((uintptr_t)srcva < UTOP){
f01050ee:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f01050f5:	0f 87 88 00 00 00    	ja     f0105183 <syscall+0x4c7>
			return -E_INVAL;
f01050fb:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if ((uintptr_t)srcva % PGSIZE != 0)
f0105100:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0105107:	0f 85 00 fc ff ff    	jne    f0104d0d <syscall+0x51>
		if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f010510d:	8b 55 18             	mov    0x18(%ebp),%edx
f0105110:	83 e2 05             	and    $0x5,%edx
f0105113:	83 fa 05             	cmp    $0x5,%edx
f0105116:	0f 85 f1 fb ff ff    	jne    f0104d0d <syscall+0x51>
			(perm | (PTE_AVAIL | PTE_W)) != (PTE_U | PTE_P | PTE_AVAIL | PTE_W))
f010511c:	8b 55 18             	mov    0x18(%ebp),%edx
f010511f:	81 ca 02 0e 00 00    	or     $0xe02,%edx
		if ((perm & (PTE_U | PTE_P)) != (PTE_U | PTE_P) ||
f0105125:	81 fa 07 0e 00 00    	cmp    $0xe07,%edx
f010512b:	0f 85 dc fb ff ff    	jne    f0104d0d <syscall+0x51>
		struct PageInfo* pg = page_lookup(curenv->env_pgdir, srcva, &pte);
f0105131:	e8 6d 13 00 00       	call   f01064a3 <cpunum>
f0105136:	83 ec 04             	sub    $0x4,%esp
f0105139:	8d 55 f4             	lea    -0xc(%ebp),%edx
f010513c:	52                   	push   %edx
f010513d:	ff 75 14             	pushl  0x14(%ebp)
f0105140:	6b c0 74             	imul   $0x74,%eax,%eax
f0105143:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f0105149:	ff 70 60             	pushl  0x60(%eax)
f010514c:	e8 a2 c4 ff ff       	call   f01015f3 <page_lookup>
f0105151:	89 c2                	mov    %eax,%edx
		if (pg == NULL)
f0105153:	83 c4 10             	add    $0x10,%esp
			return -E_INVAL;
f0105156:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (pg == NULL)
f010515b:	85 d2                	test   %edx,%edx
f010515d:	0f 84 aa fb ff ff    	je     f0104d0d <syscall+0x51>
		if ((perm & PTE_W) == PTE_W &&
f0105163:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0105167:	74 0c                	je     f0105175 <syscall+0x4b9>
f0105169:	8b 4d f4             	mov    -0xc(%ebp),%ecx
f010516c:	f6 01 02             	testb  $0x2,(%ecx)
f010516f:	0f 84 98 fb ff ff    	je     f0104d0d <syscall+0x51>
		if ((uintptr_t)env->env_ipc_dstva < UTOP){
f0105175:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105178:	8b 48 6c             	mov    0x6c(%eax),%ecx
f010517b:	81 f9 ff ff bf ee    	cmp    $0xeebfffff,%ecx
f0105181:	76 3c                	jbe    f01051bf <syscall+0x503>
	env->env_ipc_recving = 0;
f0105183:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0105186:	c6 40 68 00          	movb   $0x0,0x68(%eax)
	env->env_ipc_from = curenv->env_id;
f010518a:	e8 14 13 00 00       	call   f01064a3 <cpunum>
f010518f:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0105192:	6b c0 74             	imul   $0x74,%eax,%eax
f0105195:	8b 80 28 70 21 f0    	mov    -0xfde8fd8(%eax),%eax
f010519b:	8b 40 48             	mov    0x48(%eax),%eax
f010519e:	89 42 74             	mov    %eax,0x74(%edx)
	env->env_ipc_value = value;
f01051a1:	8b 45 10             	mov    0x10(%ebp),%eax
f01051a4:	89 42 70             	mov    %eax,0x70(%edx)
	env->env_tf.tf_regs.reg_eax = 0;
f01051a7:	c7 42 1c 00 00 00 00 	movl   $0x0,0x1c(%edx)
	env->env_status = ENV_RUNNABLE;
f01051ae:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	return 0;
f01051b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01051ba:	e9 4e fb ff ff       	jmp    f0104d0d <syscall+0x51>
			result = page_insert(env->env_pgdir, pg, env->env_ipc_dstva, perm);
f01051bf:	ff 75 18             	pushl  0x18(%ebp)
f01051c2:	51                   	push   %ecx
f01051c3:	52                   	push   %edx
f01051c4:	ff 70 60             	pushl  0x60(%eax)
f01051c7:	e8 0f c5 ff ff       	call   f01016db <page_insert>
			if (result < 0)
f01051cc:	83 c4 10             	add    $0x10,%esp
f01051cf:	85 c0                	test   %eax,%eax
f01051d1:	78 0b                	js     f01051de <syscall+0x522>
				env->env_ipc_perm = perm;
f01051d3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01051d6:	8b 7d 18             	mov    0x18(%ebp),%edi
f01051d9:	89 78 78             	mov    %edi,0x78(%eax)
f01051dc:	eb a5                	jmp    f0105183 <syscall+0x4c7>
				return -E_NO_MEM;
f01051de:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01051e3:	e9 25 fb ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f01051e8:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01051ed:	e9 1b fb ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_IPC_NOT_RECV;
f01051f2:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax
		return sys_ipc_try_send((envid_t)a1, (uint32_t)a2, (void*) a3, (uint32_t)a4);
f01051f7:	e9 11 fb ff ff       	jmp    f0104d0d <syscall+0x51>
		return sys_env_set_trapframe((envid_t)a1, (struct Trapframe*)a2);
f01051fc:	8b 75 10             	mov    0x10(%ebp),%esi
	if (envid2env(envid, &env, 1) < 0)
f01051ff:	83 ec 04             	sub    $0x4,%esp
f0105202:	6a 01                	push   $0x1
f0105204:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0105207:	50                   	push   %eax
f0105208:	ff 75 0c             	pushl  0xc(%ebp)
f010520b:	e8 01 e3 ff ff       	call   f0103511 <envid2env>
f0105210:	83 c4 10             	add    $0x10,%esp
f0105213:	85 c0                	test   %eax,%eax
f0105215:	78 28                	js     f010523f <syscall+0x583>
	env->env_tf = *tf;
f0105217:	b9 11 00 00 00       	mov    $0x11,%ecx
f010521c:	8b 7d f4             	mov    -0xc(%ebp),%edi
f010521f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	env->env_tf.tf_cs |= 3;
f0105221:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0105224:	66 83 4a 34 03       	orw    $0x3,0x34(%edx)
	env->env_tf.tf_eflags &= ~FL_IOPL_MASK;
f0105229:	8b 42 38             	mov    0x38(%edx),%eax
f010522c:	80 e4 cf             	and    $0xcf,%ah
f010522f:	80 cc 02             	or     $0x2,%ah
f0105232:	89 42 38             	mov    %eax,0x38(%edx)
	return 0;
f0105235:	b8 00 00 00 00       	mov    $0x0,%eax
f010523a:	e9 ce fa ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_BAD_ENV;
f010523f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
		return sys_env_set_trapframe((envid_t)a1, (struct Trapframe*)a2);
f0105244:	e9 c4 fa ff ff       	jmp    f0104d0d <syscall+0x51>
		return -E_INVAL;
f0105249:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010524e:	e9 ba fa ff ff       	jmp    f0104d0d <syscall+0x51>

f0105253 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0105253:	55                   	push   %ebp
f0105254:	89 e5                	mov    %esp,%ebp
f0105256:	57                   	push   %edi
f0105257:	56                   	push   %esi
f0105258:	53                   	push   %ebx
f0105259:	83 ec 14             	sub    $0x14,%esp
f010525c:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010525f:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105262:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0105265:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0105268:	8b 32                	mov    (%edx),%esi
f010526a:	8b 01                	mov    (%ecx),%eax
f010526c:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010526f:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0105276:	eb 2f                	jmp    f01052a7 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0105278:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f010527b:	39 c6                	cmp    %eax,%esi
f010527d:	7f 49                	jg     f01052c8 <stab_binsearch+0x75>
f010527f:	0f b6 0a             	movzbl (%edx),%ecx
f0105282:	83 ea 0c             	sub    $0xc,%edx
f0105285:	39 f9                	cmp    %edi,%ecx
f0105287:	75 ef                	jne    f0105278 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0105289:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010528c:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010528f:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0105293:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0105296:	73 35                	jae    f01052cd <stab_binsearch+0x7a>
			*region_left = m;
f0105298:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010529b:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010529d:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f01052a0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f01052a7:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f01052aa:	7f 4e                	jg     f01052fa <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f01052ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01052af:	01 f0                	add    %esi,%eax
f01052b1:	89 c3                	mov    %eax,%ebx
f01052b3:	c1 eb 1f             	shr    $0x1f,%ebx
f01052b6:	01 c3                	add    %eax,%ebx
f01052b8:	d1 fb                	sar    %ebx
f01052ba:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01052bd:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01052c0:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f01052c4:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f01052c6:	eb b3                	jmp    f010527b <stab_binsearch+0x28>
			l = true_m + 1;
f01052c8:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f01052cb:	eb da                	jmp    f01052a7 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f01052cd:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01052d0:	76 14                	jbe    f01052e6 <stab_binsearch+0x93>
			*region_right = m - 1;
f01052d2:	83 e8 01             	sub    $0x1,%eax
f01052d5:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01052d8:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01052db:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f01052dd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01052e4:	eb c1                	jmp    f01052a7 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01052e6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01052e9:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01052eb:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01052ef:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01052f1:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01052f8:	eb ad                	jmp    f01052a7 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01052fa:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01052fe:	74 16                	je     f0105316 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0105300:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105303:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0105305:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0105308:	8b 0e                	mov    (%esi),%ecx
f010530a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010530d:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0105310:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0105314:	eb 12                	jmp    f0105328 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0105316:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105319:	8b 00                	mov    (%eax),%eax
f010531b:	83 e8 01             	sub    $0x1,%eax
f010531e:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0105321:	89 07                	mov    %eax,(%edi)
f0105323:	eb 16                	jmp    f010533b <stab_binsearch+0xe8>
		     l--)
f0105325:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0105328:	39 c1                	cmp    %eax,%ecx
f010532a:	7d 0a                	jge    f0105336 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f010532c:	0f b6 1a             	movzbl (%edx),%ebx
f010532f:	83 ea 0c             	sub    $0xc,%edx
f0105332:	39 fb                	cmp    %edi,%ebx
f0105334:	75 ef                	jne    f0105325 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0105336:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105339:	89 07                	mov    %eax,(%edi)
	}
}
f010533b:	83 c4 14             	add    $0x14,%esp
f010533e:	5b                   	pop    %ebx
f010533f:	5e                   	pop    %esi
f0105340:	5f                   	pop    %edi
f0105341:	5d                   	pop    %ebp
f0105342:	c3                   	ret    

f0105343 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0105343:	55                   	push   %ebp
f0105344:	89 e5                	mov    %esp,%ebp
f0105346:	57                   	push   %edi
f0105347:	56                   	push   %esi
f0105348:	53                   	push   %ebx
f0105349:	83 ec 4c             	sub    $0x4c,%esp
f010534c:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010534f:	c7 07 64 85 10 f0    	movl   $0xf0108564,(%edi)
	info->eip_line = 0;
f0105355:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f010535c:	c7 47 08 64 85 10 f0 	movl   $0xf0108564,0x8(%edi)
	info->eip_fn_namelen = 9;
f0105363:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f010536a:	8b 45 08             	mov    0x8(%ebp),%eax
f010536d:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f0105370:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0105377:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f010537c:	0f 86 2a 01 00 00    	jbe    f01054ac <debuginfo_eip+0x169>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0105382:	c7 45 bc b8 82 11 f0 	movl   $0xf01182b8,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0105389:	c7 45 b4 a9 49 11 f0 	movl   $0xf01149a9,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0105390:	be a8 49 11 f0       	mov    $0xf01149a8,%esi
		stabs = __STAB_BEGIN__;
f0105395:	c7 45 b8 10 8b 10 f0 	movl   $0xf0108b10,-0x48(%ebp)
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
		if (user_mem_check(curenv, usd -> stabstr, sizeof(usd -> stabstr), PTE_P) < 0) return -1;
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010539c:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010539f:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f01053a2:	0f 83 72 02 00 00    	jae    f010561a <debuginfo_eip+0x2d7>
f01053a8:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f01053ac:	0f 85 6f 02 00 00    	jne    f0105621 <debuginfo_eip+0x2de>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01053b2:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01053b9:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f01053bc:	29 de                	sub    %ebx,%esi
f01053be:	c1 fe 02             	sar    $0x2,%esi
f01053c1:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f01053c7:	83 e8 01             	sub    $0x1,%eax
f01053ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01053cd:	83 ec 08             	sub    $0x8,%esp
f01053d0:	ff 75 08             	pushl  0x8(%ebp)
f01053d3:	6a 64                	push   $0x64
f01053d5:	8d 55 e0             	lea    -0x20(%ebp),%edx
f01053d8:	89 d1                	mov    %edx,%ecx
f01053da:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01053dd:	89 d8                	mov    %ebx,%eax
f01053df:	e8 6f fe ff ff       	call   f0105253 <stab_binsearch>
	if (lfile == 0)
f01053e4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01053e7:	83 c4 10             	add    $0x10,%esp
f01053ea:	85 c0                	test   %eax,%eax
f01053ec:	0f 84 36 02 00 00    	je     f0105628 <debuginfo_eip+0x2e5>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01053f2:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01053f5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01053f8:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01053fb:	83 ec 08             	sub    $0x8,%esp
f01053fe:	ff 75 08             	pushl  0x8(%ebp)
f0105401:	6a 24                	push   $0x24
f0105403:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0105406:	89 d1                	mov    %edx,%ecx
f0105408:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010540b:	89 d8                	mov    %ebx,%eax
f010540d:	e8 41 fe ff ff       	call   f0105253 <stab_binsearch>

	if (lfun <= rfun) {
f0105412:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105415:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105418:	83 c4 10             	add    $0x10,%esp
f010541b:	39 d0                	cmp    %edx,%eax
f010541d:	0f 8f 29 01 00 00    	jg     f010554c <debuginfo_eip+0x209>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0105423:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0105426:	8d 34 8b             	lea    (%ebx,%ecx,4),%esi
f0105429:	8b 1e                	mov    (%esi),%ebx
f010542b:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f010542e:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f0105431:	39 cb                	cmp    %ecx,%ebx
f0105433:	73 06                	jae    f010543b <debuginfo_eip+0xf8>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0105435:	03 5d b4             	add    -0x4c(%ebp),%ebx
f0105438:	89 5f 08             	mov    %ebx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f010543b:	8b 4e 08             	mov    0x8(%esi),%ecx
f010543e:	89 4f 10             	mov    %ecx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0105441:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f0105444:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0105447:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010544a:	83 ec 08             	sub    $0x8,%esp
f010544d:	6a 3a                	push   $0x3a
f010544f:	ff 77 08             	pushl  0x8(%edi)
f0105452:	e8 0a 0a 00 00       	call   f0105e61 <strfind>
f0105457:	2b 47 08             	sub    0x8(%edi),%eax
f010545a:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular c
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f010545d:	83 c4 08             	add    $0x8,%esp
f0105460:	ff 75 08             	pushl  0x8(%ebp)
f0105463:	6a 44                	push   $0x44
f0105465:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0105468:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010546b:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f010546e:	89 d8                	mov    %ebx,%eax
f0105470:	e8 de fd ff ff       	call   f0105253 <stab_binsearch>
	if (lline <= rline)
f0105475:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0105478:	83 c4 10             	add    $0x10,%esp
f010547b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010547e:	0f 8f ab 01 00 00    	jg     f010562f <debuginfo_eip+0x2ec>
		info->eip_line = stabs[lline].n_desc;
f0105484:	89 d0                	mov    %edx,%eax
f0105486:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0105489:	c1 e2 02             	shl    $0x2,%edx
f010548c:	0f b7 4c 13 06       	movzwl 0x6(%ebx,%edx,1),%ecx
f0105491:	89 4f 04             	mov    %ecx,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0105494:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0105497:	8d 54 13 04          	lea    0x4(%ebx,%edx,1),%edx
f010549b:	c6 45 c7 00          	movb   $0x0,-0x39(%ebp)
f010549f:	bb 01 00 00 00       	mov    $0x1,%ebx
f01054a4:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01054a7:	e9 c0 00 00 00       	jmp    f010556c <debuginfo_eip+0x229>
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_P) < 0) return -1;
f01054ac:	e8 f2 0f 00 00       	call   f01064a3 <cpunum>
f01054b1:	6a 01                	push   $0x1
f01054b3:	6a 04                	push   $0x4
f01054b5:	68 00 00 20 00       	push   $0x200000
f01054ba:	6b c0 74             	imul   $0x74,%eax,%eax
f01054bd:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f01054c3:	e8 f8 de ff ff       	call   f01033c0 <user_mem_check>
f01054c8:	83 c4 10             	add    $0x10,%esp
f01054cb:	85 c0                	test   %eax,%eax
f01054cd:	0f 88 39 01 00 00    	js     f010560c <debuginfo_eip+0x2c9>
		stabs = usd->stabs;
f01054d3:	a1 00 00 20 00       	mov    0x200000,%eax
f01054d8:	89 c3                	mov    %eax,%ebx
f01054da:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f01054dd:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f01054e3:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f01054e9:	89 4d b4             	mov    %ecx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f01054ec:	8b 0d 0c 00 20 00    	mov    0x20000c,%ecx
f01054f2:	89 4d bc             	mov    %ecx,-0x44(%ebp)
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
f01054f5:	e8 a9 0f 00 00       	call   f01064a3 <cpunum>
f01054fa:	6a 01                	push   $0x1
f01054fc:	6a 04                	push   $0x4
f01054fe:	53                   	push   %ebx
f01054ff:	6b c0 74             	imul   $0x74,%eax,%eax
f0105502:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0105508:	e8 b3 de ff ff       	call   f01033c0 <user_mem_check>
f010550d:	83 c4 10             	add    $0x10,%esp
f0105510:	85 c0                	test   %eax,%eax
f0105512:	0f 88 fb 00 00 00    	js     f0105613 <debuginfo_eip+0x2d0>
		if (user_mem_check(curenv, usd -> stabstr, sizeof(usd -> stabstr), PTE_P) < 0) return -1;
f0105518:	a1 08 00 20 00       	mov    0x200008,%eax
f010551d:	89 c3                	mov    %eax,%ebx
f010551f:	e8 7f 0f 00 00       	call   f01064a3 <cpunum>
f0105524:	6a 01                	push   $0x1
f0105526:	6a 04                	push   $0x4
f0105528:	53                   	push   %ebx
f0105529:	6b c0 74             	imul   $0x74,%eax,%eax
f010552c:	ff b0 28 70 21 f0    	pushl  -0xfde8fd8(%eax)
f0105532:	e8 89 de ff ff       	call   f01033c0 <user_mem_check>
f0105537:	83 c4 10             	add    $0x10,%esp
f010553a:	85 c0                	test   %eax,%eax
f010553c:	0f 89 5a fe ff ff    	jns    f010539c <debuginfo_eip+0x59>
f0105542:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105547:	e9 ef 00 00 00       	jmp    f010563b <debuginfo_eip+0x2f8>
		info->eip_fn_addr = addr;
f010554c:	8b 45 08             	mov    0x8(%ebp),%eax
f010554f:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f0105552:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105555:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0105558:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010555b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010555e:	e9 e7 fe ff ff       	jmp    f010544a <debuginfo_eip+0x107>
f0105563:	83 e8 01             	sub    $0x1,%eax
f0105566:	83 ea 0c             	sub    $0xc,%edx
f0105569:	88 5d c7             	mov    %bl,-0x39(%ebp)
f010556c:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f010556f:	39 c6                	cmp    %eax,%esi
f0105571:	7f 24                	jg     f0105597 <debuginfo_eip+0x254>
	       && stabs[lline].n_type != N_SOL
f0105573:	0f b6 0a             	movzbl (%edx),%ecx
f0105576:	80 f9 84             	cmp    $0x84,%cl
f0105579:	74 46                	je     f01055c1 <debuginfo_eip+0x27e>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010557b:	80 f9 64             	cmp    $0x64,%cl
f010557e:	75 e3                	jne    f0105563 <debuginfo_eip+0x220>
f0105580:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0105584:	74 dd                	je     f0105563 <debuginfo_eip+0x220>
f0105586:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105589:	80 7d c7 00          	cmpb   $0x0,-0x39(%ebp)
f010558d:	74 3b                	je     f01055ca <debuginfo_eip+0x287>
f010558f:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0105592:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0105595:	eb 33                	jmp    f01055ca <debuginfo_eip+0x287>
f0105597:	8b 7d 0c             	mov    0xc(%ebp),%edi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010559a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010559d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01055a0:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01055a5:	39 da                	cmp    %ebx,%edx
f01055a7:	0f 8d 8e 00 00 00    	jge    f010563b <debuginfo_eip+0x2f8>
		for (lline = lfun + 1;
f01055ad:	83 c2 01             	add    $0x1,%edx
f01055b0:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01055b3:	89 d0                	mov    %edx,%eax
f01055b5:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01055b8:	8b 75 b8             	mov    -0x48(%ebp),%esi
f01055bb:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f01055bf:	eb 32                	jmp    f01055f3 <debuginfo_eip+0x2b0>
f01055c1:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01055c4:	80 7d c7 00          	cmpb   $0x0,-0x39(%ebp)
f01055c8:	75 1d                	jne    f01055e7 <debuginfo_eip+0x2a4>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01055ca:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01055cd:	8b 75 b8             	mov    -0x48(%ebp),%esi
f01055d0:	8b 14 86             	mov    (%esi,%eax,4),%edx
f01055d3:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01055d6:	8b 75 b4             	mov    -0x4c(%ebp),%esi
f01055d9:	29 f0                	sub    %esi,%eax
f01055db:	39 c2                	cmp    %eax,%edx
f01055dd:	73 bb                	jae    f010559a <debuginfo_eip+0x257>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01055df:	89 f0                	mov    %esi,%eax
f01055e1:	01 d0                	add    %edx,%eax
f01055e3:	89 07                	mov    %eax,(%edi)
f01055e5:	eb b3                	jmp    f010559a <debuginfo_eip+0x257>
f01055e7:	8b 75 c0             	mov    -0x40(%ebp),%esi
f01055ea:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01055ed:	eb db                	jmp    f01055ca <debuginfo_eip+0x287>
			info->eip_fn_narg++;
f01055ef:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f01055f3:	39 c3                	cmp    %eax,%ebx
f01055f5:	7e 3f                	jle    f0105636 <debuginfo_eip+0x2f3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01055f7:	0f b6 0a             	movzbl (%edx),%ecx
f01055fa:	83 c0 01             	add    $0x1,%eax
f01055fd:	83 c2 0c             	add    $0xc,%edx
f0105600:	80 f9 a0             	cmp    $0xa0,%cl
f0105603:	74 ea                	je     f01055ef <debuginfo_eip+0x2ac>
	return 0;
f0105605:	b8 00 00 00 00       	mov    $0x0,%eax
f010560a:	eb 2f                	jmp    f010563b <debuginfo_eip+0x2f8>
		if (user_mem_check(curenv, usd, sizeof(usd), PTE_P) < 0) return -1;
f010560c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105611:	eb 28                	jmp    f010563b <debuginfo_eip+0x2f8>
		if (user_mem_check(curenv, usd -> stabs, sizeof(usd -> stabs), PTE_P) < 0) return -1;
f0105613:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105618:	eb 21                	jmp    f010563b <debuginfo_eip+0x2f8>
		return -1;
f010561a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010561f:	eb 1a                	jmp    f010563b <debuginfo_eip+0x2f8>
f0105621:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105626:	eb 13                	jmp    f010563b <debuginfo_eip+0x2f8>
		return -1;
f0105628:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010562d:	eb 0c                	jmp    f010563b <debuginfo_eip+0x2f8>
		return -1;
f010562f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0105634:	eb 05                	jmp    f010563b <debuginfo_eip+0x2f8>
	return 0;
f0105636:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010563b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010563e:	5b                   	pop    %ebx
f010563f:	5e                   	pop    %esi
f0105640:	5f                   	pop    %edi
f0105641:	5d                   	pop    %ebp
f0105642:	c3                   	ret    

f0105643 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0105643:	55                   	push   %ebp
f0105644:	89 e5                	mov    %esp,%ebp
f0105646:	57                   	push   %edi
f0105647:	56                   	push   %esi
f0105648:	53                   	push   %ebx
f0105649:	83 ec 1c             	sub    $0x1c,%esp
f010564c:	89 c7                	mov    %eax,%edi
f010564e:	89 d6                	mov    %edx,%esi
f0105650:	8b 45 08             	mov    0x8(%ebp),%eax
f0105653:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105656:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0105659:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010565c:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010565f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105664:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0105667:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010566a:	39 d3                	cmp    %edx,%ebx
f010566c:	72 05                	jb     f0105673 <printnum+0x30>
f010566e:	39 45 10             	cmp    %eax,0x10(%ebp)
f0105671:	77 7a                	ja     f01056ed <printnum+0xaa>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0105673:	83 ec 0c             	sub    $0xc,%esp
f0105676:	ff 75 18             	pushl  0x18(%ebp)
f0105679:	8b 45 14             	mov    0x14(%ebp),%eax
f010567c:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010567f:	53                   	push   %ebx
f0105680:	ff 75 10             	pushl  0x10(%ebp)
f0105683:	83 ec 08             	sub    $0x8,%esp
f0105686:	ff 75 e4             	pushl  -0x1c(%ebp)
f0105689:	ff 75 e0             	pushl  -0x20(%ebp)
f010568c:	ff 75 dc             	pushl  -0x24(%ebp)
f010568f:	ff 75 d8             	pushl  -0x28(%ebp)
f0105692:	e8 09 12 00 00       	call   f01068a0 <__udivdi3>
f0105697:	83 c4 18             	add    $0x18,%esp
f010569a:	52                   	push   %edx
f010569b:	50                   	push   %eax
f010569c:	89 f2                	mov    %esi,%edx
f010569e:	89 f8                	mov    %edi,%eax
f01056a0:	e8 9e ff ff ff       	call   f0105643 <printnum>
f01056a5:	83 c4 20             	add    $0x20,%esp
f01056a8:	eb 13                	jmp    f01056bd <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01056aa:	83 ec 08             	sub    $0x8,%esp
f01056ad:	56                   	push   %esi
f01056ae:	ff 75 18             	pushl  0x18(%ebp)
f01056b1:	ff d7                	call   *%edi
f01056b3:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f01056b6:	83 eb 01             	sub    $0x1,%ebx
f01056b9:	85 db                	test   %ebx,%ebx
f01056bb:	7f ed                	jg     f01056aa <printnum+0x67>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01056bd:	83 ec 08             	sub    $0x8,%esp
f01056c0:	56                   	push   %esi
f01056c1:	83 ec 04             	sub    $0x4,%esp
f01056c4:	ff 75 e4             	pushl  -0x1c(%ebp)
f01056c7:	ff 75 e0             	pushl  -0x20(%ebp)
f01056ca:	ff 75 dc             	pushl  -0x24(%ebp)
f01056cd:	ff 75 d8             	pushl  -0x28(%ebp)
f01056d0:	e8 eb 12 00 00       	call   f01069c0 <__umoddi3>
f01056d5:	83 c4 14             	add    $0x14,%esp
f01056d8:	0f be 80 6e 85 10 f0 	movsbl -0xfef7a92(%eax),%eax
f01056df:	50                   	push   %eax
f01056e0:	ff d7                	call   *%edi
}
f01056e2:	83 c4 10             	add    $0x10,%esp
f01056e5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056e8:	5b                   	pop    %ebx
f01056e9:	5e                   	pop    %esi
f01056ea:	5f                   	pop    %edi
f01056eb:	5d                   	pop    %ebp
f01056ec:	c3                   	ret    
f01056ed:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01056f0:	eb c4                	jmp    f01056b6 <printnum+0x73>

f01056f2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01056f2:	55                   	push   %ebp
f01056f3:	89 e5                	mov    %esp,%ebp
f01056f5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01056f8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01056fc:	8b 10                	mov    (%eax),%edx
f01056fe:	3b 50 04             	cmp    0x4(%eax),%edx
f0105701:	73 0a                	jae    f010570d <sprintputch+0x1b>
		*b->buf++ = ch;
f0105703:	8d 4a 01             	lea    0x1(%edx),%ecx
f0105706:	89 08                	mov    %ecx,(%eax)
f0105708:	8b 45 08             	mov    0x8(%ebp),%eax
f010570b:	88 02                	mov    %al,(%edx)
}
f010570d:	5d                   	pop    %ebp
f010570e:	c3                   	ret    

f010570f <printfmt>:
{
f010570f:	55                   	push   %ebp
f0105710:	89 e5                	mov    %esp,%ebp
f0105712:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0105715:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0105718:	50                   	push   %eax
f0105719:	ff 75 10             	pushl  0x10(%ebp)
f010571c:	ff 75 0c             	pushl  0xc(%ebp)
f010571f:	ff 75 08             	pushl  0x8(%ebp)
f0105722:	e8 05 00 00 00       	call   f010572c <vprintfmt>
}
f0105727:	83 c4 10             	add    $0x10,%esp
f010572a:	c9                   	leave  
f010572b:	c3                   	ret    

f010572c <vprintfmt>:
{
f010572c:	55                   	push   %ebp
f010572d:	89 e5                	mov    %esp,%ebp
f010572f:	57                   	push   %edi
f0105730:	56                   	push   %esi
f0105731:	53                   	push   %ebx
f0105732:	83 ec 2c             	sub    $0x2c,%esp
f0105735:	8b 75 08             	mov    0x8(%ebp),%esi
f0105738:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010573b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010573e:	e9 c1 03 00 00       	jmp    f0105b04 <vprintfmt+0x3d8>
		padc = ' ';
f0105743:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0105747:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f010574e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;
f0105755:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010575c:	b9 00 00 00 00       	mov    $0x0,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0105761:	8d 47 01             	lea    0x1(%edi),%eax
f0105764:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105767:	0f b6 17             	movzbl (%edi),%edx
f010576a:	8d 42 dd             	lea    -0x23(%edx),%eax
f010576d:	3c 55                	cmp    $0x55,%al
f010576f:	0f 87 12 04 00 00    	ja     f0105b87 <vprintfmt+0x45b>
f0105775:	0f b6 c0             	movzbl %al,%eax
f0105778:	ff 24 85 c0 86 10 f0 	jmp    *-0xfef7940(,%eax,4)
f010577f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0105782:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0105786:	eb d9                	jmp    f0105761 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0105788:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010578b:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010578f:	eb d0                	jmp    f0105761 <vprintfmt+0x35>
		switch (ch = *(unsigned char *) fmt++) {
f0105791:	0f b6 d2             	movzbl %dl,%edx
f0105794:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0105797:	b8 00 00 00 00       	mov    $0x0,%eax
f010579c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
				precision = precision * 10 + ch - '0';
f010579f:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01057a2:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01057a6:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01057a9:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01057ac:	83 f9 09             	cmp    $0x9,%ecx
f01057af:	77 55                	ja     f0105806 <vprintfmt+0xda>
			for (precision = 0; ; ++fmt) {
f01057b1:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01057b4:	eb e9                	jmp    f010579f <vprintfmt+0x73>
			precision = va_arg(ap, int);
f01057b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01057b9:	8b 00                	mov    (%eax),%eax
f01057bb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01057be:	8b 45 14             	mov    0x14(%ebp),%eax
f01057c1:	8d 40 04             	lea    0x4(%eax),%eax
f01057c4:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01057c7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01057ca:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01057ce:	79 91                	jns    f0105761 <vprintfmt+0x35>
				width = precision, precision = -1;
f01057d0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01057d3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01057d6:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01057dd:	eb 82                	jmp    f0105761 <vprintfmt+0x35>
f01057df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01057e2:	85 c0                	test   %eax,%eax
f01057e4:	ba 00 00 00 00       	mov    $0x0,%edx
f01057e9:	0f 49 d0             	cmovns %eax,%edx
f01057ec:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01057ef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01057f2:	e9 6a ff ff ff       	jmp    f0105761 <vprintfmt+0x35>
f01057f7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01057fa:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0105801:	e9 5b ff ff ff       	jmp    f0105761 <vprintfmt+0x35>
f0105806:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0105809:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010580c:	eb bc                	jmp    f01057ca <vprintfmt+0x9e>
			lflag++;
f010580e:	83 c1 01             	add    $0x1,%ecx
		switch (ch = *(unsigned char *) fmt++) {
f0105811:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0105814:	e9 48 ff ff ff       	jmp    f0105761 <vprintfmt+0x35>
			putch(va_arg(ap, int), putdat);
f0105819:	8b 45 14             	mov    0x14(%ebp),%eax
f010581c:	8d 78 04             	lea    0x4(%eax),%edi
f010581f:	83 ec 08             	sub    $0x8,%esp
f0105822:	53                   	push   %ebx
f0105823:	ff 30                	pushl  (%eax)
f0105825:	ff d6                	call   *%esi
			break;
f0105827:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010582a:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010582d:	e9 cf 02 00 00       	jmp    f0105b01 <vprintfmt+0x3d5>
			err = va_arg(ap, int);
f0105832:	8b 45 14             	mov    0x14(%ebp),%eax
f0105835:	8d 78 04             	lea    0x4(%eax),%edi
f0105838:	8b 00                	mov    (%eax),%eax
f010583a:	99                   	cltd   
f010583b:	31 d0                	xor    %edx,%eax
f010583d:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010583f:	83 f8 0f             	cmp    $0xf,%eax
f0105842:	7f 23                	jg     f0105867 <vprintfmt+0x13b>
f0105844:	8b 14 85 20 88 10 f0 	mov    -0xfef77e0(,%eax,4),%edx
f010584b:	85 d2                	test   %edx,%edx
f010584d:	74 18                	je     f0105867 <vprintfmt+0x13b>
				printfmt(putch, putdat, "%s", p);
f010584f:	52                   	push   %edx
f0105850:	68 cc 73 10 f0       	push   $0xf01073cc
f0105855:	53                   	push   %ebx
f0105856:	56                   	push   %esi
f0105857:	e8 b3 fe ff ff       	call   f010570f <printfmt>
f010585c:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010585f:	89 7d 14             	mov    %edi,0x14(%ebp)
f0105862:	e9 9a 02 00 00       	jmp    f0105b01 <vprintfmt+0x3d5>
				printfmt(putch, putdat, "error %d", err);
f0105867:	50                   	push   %eax
f0105868:	68 86 85 10 f0       	push   $0xf0108586
f010586d:	53                   	push   %ebx
f010586e:	56                   	push   %esi
f010586f:	e8 9b fe ff ff       	call   f010570f <printfmt>
f0105874:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0105877:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010587a:	e9 82 02 00 00       	jmp    f0105b01 <vprintfmt+0x3d5>
			if ((p = va_arg(ap, char *)) == NULL)
f010587f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105882:	83 c0 04             	add    $0x4,%eax
f0105885:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0105888:	8b 45 14             	mov    0x14(%ebp),%eax
f010588b:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f010588d:	85 ff                	test   %edi,%edi
f010588f:	b8 7f 85 10 f0       	mov    $0xf010857f,%eax
f0105894:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0105897:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010589b:	0f 8e bd 00 00 00    	jle    f010595e <vprintfmt+0x232>
f01058a1:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01058a5:	75 0e                	jne    f01058b5 <vprintfmt+0x189>
f01058a7:	89 75 08             	mov    %esi,0x8(%ebp)
f01058aa:	8b 75 d0             	mov    -0x30(%ebp),%esi
f01058ad:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f01058b0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01058b3:	eb 6d                	jmp    f0105922 <vprintfmt+0x1f6>
				for (width -= strnlen(p, precision); width > 0; width--)
f01058b5:	83 ec 08             	sub    $0x8,%esp
f01058b8:	ff 75 d0             	pushl  -0x30(%ebp)
f01058bb:	57                   	push   %edi
f01058bc:	e8 5c 04 00 00       	call   f0105d1d <strnlen>
f01058c1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01058c4:	29 c1                	sub    %eax,%ecx
f01058c6:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01058c9:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01058cc:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01058d0:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01058d3:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01058d6:	89 cf                	mov    %ecx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01058d8:	eb 0f                	jmp    f01058e9 <vprintfmt+0x1bd>
					putch(padc, putdat);
f01058da:	83 ec 08             	sub    $0x8,%esp
f01058dd:	53                   	push   %ebx
f01058de:	ff 75 e0             	pushl  -0x20(%ebp)
f01058e1:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f01058e3:	83 ef 01             	sub    $0x1,%edi
f01058e6:	83 c4 10             	add    $0x10,%esp
f01058e9:	85 ff                	test   %edi,%edi
f01058eb:	7f ed                	jg     f01058da <vprintfmt+0x1ae>
f01058ed:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01058f0:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01058f3:	85 c9                	test   %ecx,%ecx
f01058f5:	b8 00 00 00 00       	mov    $0x0,%eax
f01058fa:	0f 49 c1             	cmovns %ecx,%eax
f01058fd:	29 c1                	sub    %eax,%ecx
f01058ff:	89 75 08             	mov    %esi,0x8(%ebp)
f0105902:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105905:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105908:	89 cb                	mov    %ecx,%ebx
f010590a:	eb 16                	jmp    f0105922 <vprintfmt+0x1f6>
				if (altflag && (ch < ' ' || ch > '~'))
f010590c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0105910:	75 31                	jne    f0105943 <vprintfmt+0x217>
					putch(ch, putdat);
f0105912:	83 ec 08             	sub    $0x8,%esp
f0105915:	ff 75 0c             	pushl  0xc(%ebp)
f0105918:	50                   	push   %eax
f0105919:	ff 55 08             	call   *0x8(%ebp)
f010591c:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010591f:	83 eb 01             	sub    $0x1,%ebx
f0105922:	83 c7 01             	add    $0x1,%edi
f0105925:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0105929:	0f be c2             	movsbl %dl,%eax
f010592c:	85 c0                	test   %eax,%eax
f010592e:	74 59                	je     f0105989 <vprintfmt+0x25d>
f0105930:	85 f6                	test   %esi,%esi
f0105932:	78 d8                	js     f010590c <vprintfmt+0x1e0>
f0105934:	83 ee 01             	sub    $0x1,%esi
f0105937:	79 d3                	jns    f010590c <vprintfmt+0x1e0>
f0105939:	89 df                	mov    %ebx,%edi
f010593b:	8b 75 08             	mov    0x8(%ebp),%esi
f010593e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105941:	eb 37                	jmp    f010597a <vprintfmt+0x24e>
				if (altflag && (ch < ' ' || ch > '~'))
f0105943:	0f be d2             	movsbl %dl,%edx
f0105946:	83 ea 20             	sub    $0x20,%edx
f0105949:	83 fa 5e             	cmp    $0x5e,%edx
f010594c:	76 c4                	jbe    f0105912 <vprintfmt+0x1e6>
					putch('?', putdat);
f010594e:	83 ec 08             	sub    $0x8,%esp
f0105951:	ff 75 0c             	pushl  0xc(%ebp)
f0105954:	6a 3f                	push   $0x3f
f0105956:	ff 55 08             	call   *0x8(%ebp)
f0105959:	83 c4 10             	add    $0x10,%esp
f010595c:	eb c1                	jmp    f010591f <vprintfmt+0x1f3>
f010595e:	89 75 08             	mov    %esi,0x8(%ebp)
f0105961:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0105964:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0105967:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f010596a:	eb b6                	jmp    f0105922 <vprintfmt+0x1f6>
				putch(' ', putdat);
f010596c:	83 ec 08             	sub    $0x8,%esp
f010596f:	53                   	push   %ebx
f0105970:	6a 20                	push   $0x20
f0105972:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0105974:	83 ef 01             	sub    $0x1,%edi
f0105977:	83 c4 10             	add    $0x10,%esp
f010597a:	85 ff                	test   %edi,%edi
f010597c:	7f ee                	jg     f010596c <vprintfmt+0x240>
			if ((p = va_arg(ap, char *)) == NULL)
f010597e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0105981:	89 45 14             	mov    %eax,0x14(%ebp)
f0105984:	e9 78 01 00 00       	jmp    f0105b01 <vprintfmt+0x3d5>
f0105989:	89 df                	mov    %ebx,%edi
f010598b:	8b 75 08             	mov    0x8(%ebp),%esi
f010598e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105991:	eb e7                	jmp    f010597a <vprintfmt+0x24e>
	if (lflag >= 2)
f0105993:	83 f9 01             	cmp    $0x1,%ecx
f0105996:	7e 3f                	jle    f01059d7 <vprintfmt+0x2ab>
		return va_arg(*ap, long long);
f0105998:	8b 45 14             	mov    0x14(%ebp),%eax
f010599b:	8b 50 04             	mov    0x4(%eax),%edx
f010599e:	8b 00                	mov    (%eax),%eax
f01059a0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01059a3:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01059a6:	8b 45 14             	mov    0x14(%ebp),%eax
f01059a9:	8d 40 08             	lea    0x8(%eax),%eax
f01059ac:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01059af:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01059b3:	79 5c                	jns    f0105a11 <vprintfmt+0x2e5>
				putch('-', putdat);
f01059b5:	83 ec 08             	sub    $0x8,%esp
f01059b8:	53                   	push   %ebx
f01059b9:	6a 2d                	push   $0x2d
f01059bb:	ff d6                	call   *%esi
				num = -(long long) num;
f01059bd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01059c0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01059c3:	f7 da                	neg    %edx
f01059c5:	83 d1 00             	adc    $0x0,%ecx
f01059c8:	f7 d9                	neg    %ecx
f01059ca:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01059cd:	b8 0a 00 00 00       	mov    $0xa,%eax
f01059d2:	e9 10 01 00 00       	jmp    f0105ae7 <vprintfmt+0x3bb>
	else if (lflag)
f01059d7:	85 c9                	test   %ecx,%ecx
f01059d9:	75 1b                	jne    f01059f6 <vprintfmt+0x2ca>
		return va_arg(*ap, int);
f01059db:	8b 45 14             	mov    0x14(%ebp),%eax
f01059de:	8b 00                	mov    (%eax),%eax
f01059e0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01059e3:	89 c1                	mov    %eax,%ecx
f01059e5:	c1 f9 1f             	sar    $0x1f,%ecx
f01059e8:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01059eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01059ee:	8d 40 04             	lea    0x4(%eax),%eax
f01059f1:	89 45 14             	mov    %eax,0x14(%ebp)
f01059f4:	eb b9                	jmp    f01059af <vprintfmt+0x283>
		return va_arg(*ap, long);
f01059f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01059f9:	8b 00                	mov    (%eax),%eax
f01059fb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01059fe:	89 c1                	mov    %eax,%ecx
f0105a00:	c1 f9 1f             	sar    $0x1f,%ecx
f0105a03:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0105a06:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a09:	8d 40 04             	lea    0x4(%eax),%eax
f0105a0c:	89 45 14             	mov    %eax,0x14(%ebp)
f0105a0f:	eb 9e                	jmp    f01059af <vprintfmt+0x283>
			num = getint(&ap, lflag);
f0105a11:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0105a14:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0105a17:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105a1c:	e9 c6 00 00 00       	jmp    f0105ae7 <vprintfmt+0x3bb>
	if (lflag >= 2)
f0105a21:	83 f9 01             	cmp    $0x1,%ecx
f0105a24:	7e 18                	jle    f0105a3e <vprintfmt+0x312>
		return va_arg(*ap, unsigned long long);
f0105a26:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a29:	8b 10                	mov    (%eax),%edx
f0105a2b:	8b 48 04             	mov    0x4(%eax),%ecx
f0105a2e:	8d 40 08             	lea    0x8(%eax),%eax
f0105a31:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105a34:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105a39:	e9 a9 00 00 00       	jmp    f0105ae7 <vprintfmt+0x3bb>
	else if (lflag)
f0105a3e:	85 c9                	test   %ecx,%ecx
f0105a40:	75 1a                	jne    f0105a5c <vprintfmt+0x330>
		return va_arg(*ap, unsigned int);
f0105a42:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a45:	8b 10                	mov    (%eax),%edx
f0105a47:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105a4c:	8d 40 04             	lea    0x4(%eax),%eax
f0105a4f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105a52:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105a57:	e9 8b 00 00 00       	jmp    f0105ae7 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0105a5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a5f:	8b 10                	mov    (%eax),%edx
f0105a61:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105a66:	8d 40 04             	lea    0x4(%eax),%eax
f0105a69:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0105a6c:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105a71:	eb 74                	jmp    f0105ae7 <vprintfmt+0x3bb>
	if (lflag >= 2)
f0105a73:	83 f9 01             	cmp    $0x1,%ecx
f0105a76:	7e 15                	jle    f0105a8d <vprintfmt+0x361>
		return va_arg(*ap, unsigned long long);
f0105a78:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a7b:	8b 10                	mov    (%eax),%edx
f0105a7d:	8b 48 04             	mov    0x4(%eax),%ecx
f0105a80:	8d 40 08             	lea    0x8(%eax),%eax
f0105a83:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105a86:	b8 08 00 00 00       	mov    $0x8,%eax
f0105a8b:	eb 5a                	jmp    f0105ae7 <vprintfmt+0x3bb>
	else if (lflag)
f0105a8d:	85 c9                	test   %ecx,%ecx
f0105a8f:	75 17                	jne    f0105aa8 <vprintfmt+0x37c>
		return va_arg(*ap, unsigned int);
f0105a91:	8b 45 14             	mov    0x14(%ebp),%eax
f0105a94:	8b 10                	mov    (%eax),%edx
f0105a96:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105a9b:	8d 40 04             	lea    0x4(%eax),%eax
f0105a9e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105aa1:	b8 08 00 00 00       	mov    $0x8,%eax
f0105aa6:	eb 3f                	jmp    f0105ae7 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0105aa8:	8b 45 14             	mov    0x14(%ebp),%eax
f0105aab:	8b 10                	mov    (%eax),%edx
f0105aad:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105ab2:	8d 40 04             	lea    0x4(%eax),%eax
f0105ab5:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 8;
f0105ab8:	b8 08 00 00 00       	mov    $0x8,%eax
f0105abd:	eb 28                	jmp    f0105ae7 <vprintfmt+0x3bb>
			putch('0', putdat);
f0105abf:	83 ec 08             	sub    $0x8,%esp
f0105ac2:	53                   	push   %ebx
f0105ac3:	6a 30                	push   $0x30
f0105ac5:	ff d6                	call   *%esi
			putch('x', putdat);
f0105ac7:	83 c4 08             	add    $0x8,%esp
f0105aca:	53                   	push   %ebx
f0105acb:	6a 78                	push   $0x78
f0105acd:	ff d6                	call   *%esi
			num = (unsigned long long)
f0105acf:	8b 45 14             	mov    0x14(%ebp),%eax
f0105ad2:	8b 10                	mov    (%eax),%edx
f0105ad4:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0105ad9:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0105adc:	8d 40 04             	lea    0x4(%eax),%eax
f0105adf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105ae2:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0105ae7:	83 ec 0c             	sub    $0xc,%esp
f0105aea:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0105aee:	57                   	push   %edi
f0105aef:	ff 75 e0             	pushl  -0x20(%ebp)
f0105af2:	50                   	push   %eax
f0105af3:	51                   	push   %ecx
f0105af4:	52                   	push   %edx
f0105af5:	89 da                	mov    %ebx,%edx
f0105af7:	89 f0                	mov    %esi,%eax
f0105af9:	e8 45 fb ff ff       	call   f0105643 <printnum>
			break;
f0105afe:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0105b01:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105b04:	83 c7 01             	add    $0x1,%edi
f0105b07:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0105b0b:	83 f8 25             	cmp    $0x25,%eax
f0105b0e:	0f 84 2f fc ff ff    	je     f0105743 <vprintfmt+0x17>
			if (ch == '\0')
f0105b14:	85 c0                	test   %eax,%eax
f0105b16:	0f 84 8b 00 00 00    	je     f0105ba7 <vprintfmt+0x47b>
			putch(ch, putdat);
f0105b1c:	83 ec 08             	sub    $0x8,%esp
f0105b1f:	53                   	push   %ebx
f0105b20:	50                   	push   %eax
f0105b21:	ff d6                	call   *%esi
f0105b23:	83 c4 10             	add    $0x10,%esp
f0105b26:	eb dc                	jmp    f0105b04 <vprintfmt+0x3d8>
	if (lflag >= 2)
f0105b28:	83 f9 01             	cmp    $0x1,%ecx
f0105b2b:	7e 15                	jle    f0105b42 <vprintfmt+0x416>
		return va_arg(*ap, unsigned long long);
f0105b2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b30:	8b 10                	mov    (%eax),%edx
f0105b32:	8b 48 04             	mov    0x4(%eax),%ecx
f0105b35:	8d 40 08             	lea    0x8(%eax),%eax
f0105b38:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105b3b:	b8 10 00 00 00       	mov    $0x10,%eax
f0105b40:	eb a5                	jmp    f0105ae7 <vprintfmt+0x3bb>
	else if (lflag)
f0105b42:	85 c9                	test   %ecx,%ecx
f0105b44:	75 17                	jne    f0105b5d <vprintfmt+0x431>
		return va_arg(*ap, unsigned int);
f0105b46:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b49:	8b 10                	mov    (%eax),%edx
f0105b4b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105b50:	8d 40 04             	lea    0x4(%eax),%eax
f0105b53:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105b56:	b8 10 00 00 00       	mov    $0x10,%eax
f0105b5b:	eb 8a                	jmp    f0105ae7 <vprintfmt+0x3bb>
		return va_arg(*ap, unsigned long);
f0105b5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0105b60:	8b 10                	mov    (%eax),%edx
f0105b62:	b9 00 00 00 00       	mov    $0x0,%ecx
f0105b67:	8d 40 04             	lea    0x4(%eax),%eax
f0105b6a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105b6d:	b8 10 00 00 00       	mov    $0x10,%eax
f0105b72:	e9 70 ff ff ff       	jmp    f0105ae7 <vprintfmt+0x3bb>
			putch(ch, putdat);
f0105b77:	83 ec 08             	sub    $0x8,%esp
f0105b7a:	53                   	push   %ebx
f0105b7b:	6a 25                	push   $0x25
f0105b7d:	ff d6                	call   *%esi
			break;
f0105b7f:	83 c4 10             	add    $0x10,%esp
f0105b82:	e9 7a ff ff ff       	jmp    f0105b01 <vprintfmt+0x3d5>
			putch('%', putdat);
f0105b87:	83 ec 08             	sub    $0x8,%esp
f0105b8a:	53                   	push   %ebx
f0105b8b:	6a 25                	push   $0x25
f0105b8d:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105b8f:	83 c4 10             	add    $0x10,%esp
f0105b92:	89 f8                	mov    %edi,%eax
f0105b94:	eb 03                	jmp    f0105b99 <vprintfmt+0x46d>
f0105b96:	83 e8 01             	sub    $0x1,%eax
f0105b99:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0105b9d:	75 f7                	jne    f0105b96 <vprintfmt+0x46a>
f0105b9f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105ba2:	e9 5a ff ff ff       	jmp    f0105b01 <vprintfmt+0x3d5>
}
f0105ba7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105baa:	5b                   	pop    %ebx
f0105bab:	5e                   	pop    %esi
f0105bac:	5f                   	pop    %edi
f0105bad:	5d                   	pop    %ebp
f0105bae:	c3                   	ret    

f0105baf <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105baf:	55                   	push   %ebp
f0105bb0:	89 e5                	mov    %esp,%ebp
f0105bb2:	83 ec 18             	sub    $0x18,%esp
f0105bb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0105bb8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105bbb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105bbe:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105bc2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105bc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105bcc:	85 c0                	test   %eax,%eax
f0105bce:	74 26                	je     f0105bf6 <vsnprintf+0x47>
f0105bd0:	85 d2                	test   %edx,%edx
f0105bd2:	7e 22                	jle    f0105bf6 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105bd4:	ff 75 14             	pushl  0x14(%ebp)
f0105bd7:	ff 75 10             	pushl  0x10(%ebp)
f0105bda:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105bdd:	50                   	push   %eax
f0105bde:	68 f2 56 10 f0       	push   $0xf01056f2
f0105be3:	e8 44 fb ff ff       	call   f010572c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105be8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105beb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0105bee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105bf1:	83 c4 10             	add    $0x10,%esp
}
f0105bf4:	c9                   	leave  
f0105bf5:	c3                   	ret    
		return -E_INVAL;
f0105bf6:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0105bfb:	eb f7                	jmp    f0105bf4 <vsnprintf+0x45>

f0105bfd <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0105bfd:	55                   	push   %ebp
f0105bfe:	89 e5                	mov    %esp,%ebp
f0105c00:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105c03:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105c06:	50                   	push   %eax
f0105c07:	ff 75 10             	pushl  0x10(%ebp)
f0105c0a:	ff 75 0c             	pushl  0xc(%ebp)
f0105c0d:	ff 75 08             	pushl  0x8(%ebp)
f0105c10:	e8 9a ff ff ff       	call   f0105baf <vsnprintf>
	va_end(ap);

	return rc;
}
f0105c15:	c9                   	leave  
f0105c16:	c3                   	ret    

f0105c17 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105c17:	55                   	push   %ebp
f0105c18:	89 e5                	mov    %esp,%ebp
f0105c1a:	57                   	push   %edi
f0105c1b:	56                   	push   %esi
f0105c1c:	53                   	push   %ebx
f0105c1d:	83 ec 0c             	sub    $0xc,%esp
f0105c20:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f0105c23:	85 c0                	test   %eax,%eax
f0105c25:	74 11                	je     f0105c38 <readline+0x21>
		cprintf("%s", prompt);
f0105c27:	83 ec 08             	sub    $0x8,%esp
f0105c2a:	50                   	push   %eax
f0105c2b:	68 cc 73 10 f0       	push   $0xf01073cc
f0105c30:	e8 36 e1 ff ff       	call   f0103d6b <cprintf>
f0105c35:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f0105c38:	83 ec 0c             	sub    $0xc,%esp
f0105c3b:	6a 00                	push   $0x0
f0105c3d:	e8 81 ab ff ff       	call   f01007c3 <iscons>
f0105c42:	89 c7                	mov    %eax,%edi
f0105c44:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0105c47:	be 00 00 00 00       	mov    $0x0,%esi
f0105c4c:	eb 4b                	jmp    f0105c99 <readline+0x82>
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f0105c4e:	b8 00 00 00 00       	mov    $0x0,%eax
			if (c != -E_EOF)
f0105c53:	83 fb f8             	cmp    $0xfffffff8,%ebx
f0105c56:	75 08                	jne    f0105c60 <readline+0x49>
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0105c58:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105c5b:	5b                   	pop    %ebx
f0105c5c:	5e                   	pop    %esi
f0105c5d:	5f                   	pop    %edi
f0105c5e:	5d                   	pop    %ebp
f0105c5f:	c3                   	ret    
				cprintf("read error: %e\n", c);
f0105c60:	83 ec 08             	sub    $0x8,%esp
f0105c63:	53                   	push   %ebx
f0105c64:	68 7f 88 10 f0       	push   $0xf010887f
f0105c69:	e8 fd e0 ff ff       	call   f0103d6b <cprintf>
f0105c6e:	83 c4 10             	add    $0x10,%esp
			return NULL;
f0105c71:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c76:	eb e0                	jmp    f0105c58 <readline+0x41>
			if (echoing)
f0105c78:	85 ff                	test   %edi,%edi
f0105c7a:	75 05                	jne    f0105c81 <readline+0x6a>
			i--;
f0105c7c:	83 ee 01             	sub    $0x1,%esi
f0105c7f:	eb 18                	jmp    f0105c99 <readline+0x82>
				cputchar('\b');
f0105c81:	83 ec 0c             	sub    $0xc,%esp
f0105c84:	6a 08                	push   $0x8
f0105c86:	e8 17 ab ff ff       	call   f01007a2 <cputchar>
f0105c8b:	83 c4 10             	add    $0x10,%esp
f0105c8e:	eb ec                	jmp    f0105c7c <readline+0x65>
			buf[i++] = c;
f0105c90:	88 9e 80 6a 21 f0    	mov    %bl,-0xfde9580(%esi)
f0105c96:	8d 76 01             	lea    0x1(%esi),%esi
		c = getchar();
f0105c99:	e8 14 ab ff ff       	call   f01007b2 <getchar>
f0105c9e:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0105ca0:	85 c0                	test   %eax,%eax
f0105ca2:	78 aa                	js     f0105c4e <readline+0x37>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105ca4:	83 f8 08             	cmp    $0x8,%eax
f0105ca7:	0f 94 c2             	sete   %dl
f0105caa:	83 f8 7f             	cmp    $0x7f,%eax
f0105cad:	0f 94 c0             	sete   %al
f0105cb0:	08 c2                	or     %al,%dl
f0105cb2:	74 04                	je     f0105cb8 <readline+0xa1>
f0105cb4:	85 f6                	test   %esi,%esi
f0105cb6:	7f c0                	jg     f0105c78 <readline+0x61>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105cb8:	83 fb 1f             	cmp    $0x1f,%ebx
f0105cbb:	7e 1a                	jle    f0105cd7 <readline+0xc0>
f0105cbd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0105cc3:	7f 12                	jg     f0105cd7 <readline+0xc0>
			if (echoing)
f0105cc5:	85 ff                	test   %edi,%edi
f0105cc7:	74 c7                	je     f0105c90 <readline+0x79>
				cputchar(c);
f0105cc9:	83 ec 0c             	sub    $0xc,%esp
f0105ccc:	53                   	push   %ebx
f0105ccd:	e8 d0 aa ff ff       	call   f01007a2 <cputchar>
f0105cd2:	83 c4 10             	add    $0x10,%esp
f0105cd5:	eb b9                	jmp    f0105c90 <readline+0x79>
		} else if (c == '\n' || c == '\r') {
f0105cd7:	83 fb 0a             	cmp    $0xa,%ebx
f0105cda:	74 05                	je     f0105ce1 <readline+0xca>
f0105cdc:	83 fb 0d             	cmp    $0xd,%ebx
f0105cdf:	75 b8                	jne    f0105c99 <readline+0x82>
			if (echoing)
f0105ce1:	85 ff                	test   %edi,%edi
f0105ce3:	75 11                	jne    f0105cf6 <readline+0xdf>
			buf[i] = 0;
f0105ce5:	c6 86 80 6a 21 f0 00 	movb   $0x0,-0xfde9580(%esi)
			return buf;
f0105cec:	b8 80 6a 21 f0       	mov    $0xf0216a80,%eax
f0105cf1:	e9 62 ff ff ff       	jmp    f0105c58 <readline+0x41>
				cputchar('\n');
f0105cf6:	83 ec 0c             	sub    $0xc,%esp
f0105cf9:	6a 0a                	push   $0xa
f0105cfb:	e8 a2 aa ff ff       	call   f01007a2 <cputchar>
f0105d00:	83 c4 10             	add    $0x10,%esp
f0105d03:	eb e0                	jmp    f0105ce5 <readline+0xce>

f0105d05 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105d05:	55                   	push   %ebp
f0105d06:	89 e5                	mov    %esp,%ebp
f0105d08:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105d0b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d10:	eb 03                	jmp    f0105d15 <strlen+0x10>
		n++;
f0105d12:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0105d15:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105d19:	75 f7                	jne    f0105d12 <strlen+0xd>
	return n;
}
f0105d1b:	5d                   	pop    %ebp
f0105d1c:	c3                   	ret    

f0105d1d <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105d1d:	55                   	push   %ebp
f0105d1e:	89 e5                	mov    %esp,%ebp
f0105d20:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105d23:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105d26:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d2b:	eb 03                	jmp    f0105d30 <strnlen+0x13>
		n++;
f0105d2d:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105d30:	39 d0                	cmp    %edx,%eax
f0105d32:	74 06                	je     f0105d3a <strnlen+0x1d>
f0105d34:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105d38:	75 f3                	jne    f0105d2d <strnlen+0x10>
	return n;
}
f0105d3a:	5d                   	pop    %ebp
f0105d3b:	c3                   	ret    

f0105d3c <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105d3c:	55                   	push   %ebp
f0105d3d:	89 e5                	mov    %esp,%ebp
f0105d3f:	53                   	push   %ebx
f0105d40:	8b 45 08             	mov    0x8(%ebp),%eax
f0105d43:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105d46:	89 c2                	mov    %eax,%edx
f0105d48:	83 c1 01             	add    $0x1,%ecx
f0105d4b:	83 c2 01             	add    $0x1,%edx
f0105d4e:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0105d52:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105d55:	84 db                	test   %bl,%bl
f0105d57:	75 ef                	jne    f0105d48 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105d59:	5b                   	pop    %ebx
f0105d5a:	5d                   	pop    %ebp
f0105d5b:	c3                   	ret    

f0105d5c <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105d5c:	55                   	push   %ebp
f0105d5d:	89 e5                	mov    %esp,%ebp
f0105d5f:	53                   	push   %ebx
f0105d60:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105d63:	53                   	push   %ebx
f0105d64:	e8 9c ff ff ff       	call   f0105d05 <strlen>
f0105d69:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105d6c:	ff 75 0c             	pushl  0xc(%ebp)
f0105d6f:	01 d8                	add    %ebx,%eax
f0105d71:	50                   	push   %eax
f0105d72:	e8 c5 ff ff ff       	call   f0105d3c <strcpy>
	return dst;
}
f0105d77:	89 d8                	mov    %ebx,%eax
f0105d79:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105d7c:	c9                   	leave  
f0105d7d:	c3                   	ret    

f0105d7e <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105d7e:	55                   	push   %ebp
f0105d7f:	89 e5                	mov    %esp,%ebp
f0105d81:	56                   	push   %esi
f0105d82:	53                   	push   %ebx
f0105d83:	8b 75 08             	mov    0x8(%ebp),%esi
f0105d86:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105d89:	89 f3                	mov    %esi,%ebx
f0105d8b:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105d8e:	89 f2                	mov    %esi,%edx
f0105d90:	eb 0f                	jmp    f0105da1 <strncpy+0x23>
		*dst++ = *src;
f0105d92:	83 c2 01             	add    $0x1,%edx
f0105d95:	0f b6 01             	movzbl (%ecx),%eax
f0105d98:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105d9b:	80 39 01             	cmpb   $0x1,(%ecx)
f0105d9e:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0105da1:	39 da                	cmp    %ebx,%edx
f0105da3:	75 ed                	jne    f0105d92 <strncpy+0x14>
	}
	return ret;
}
f0105da5:	89 f0                	mov    %esi,%eax
f0105da7:	5b                   	pop    %ebx
f0105da8:	5e                   	pop    %esi
f0105da9:	5d                   	pop    %ebp
f0105daa:	c3                   	ret    

f0105dab <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105dab:	55                   	push   %ebp
f0105dac:	89 e5                	mov    %esp,%ebp
f0105dae:	56                   	push   %esi
f0105daf:	53                   	push   %ebx
f0105db0:	8b 75 08             	mov    0x8(%ebp),%esi
f0105db3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105db6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105db9:	89 f0                	mov    %esi,%eax
f0105dbb:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105dbf:	85 c9                	test   %ecx,%ecx
f0105dc1:	75 0b                	jne    f0105dce <strlcpy+0x23>
f0105dc3:	eb 17                	jmp    f0105ddc <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105dc5:	83 c2 01             	add    $0x1,%edx
f0105dc8:	83 c0 01             	add    $0x1,%eax
f0105dcb:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0105dce:	39 d8                	cmp    %ebx,%eax
f0105dd0:	74 07                	je     f0105dd9 <strlcpy+0x2e>
f0105dd2:	0f b6 0a             	movzbl (%edx),%ecx
f0105dd5:	84 c9                	test   %cl,%cl
f0105dd7:	75 ec                	jne    f0105dc5 <strlcpy+0x1a>
		*dst = '\0';
f0105dd9:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105ddc:	29 f0                	sub    %esi,%eax
}
f0105dde:	5b                   	pop    %ebx
f0105ddf:	5e                   	pop    %esi
f0105de0:	5d                   	pop    %ebp
f0105de1:	c3                   	ret    

f0105de2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105de2:	55                   	push   %ebp
f0105de3:	89 e5                	mov    %esp,%ebp
f0105de5:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105de8:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105deb:	eb 06                	jmp    f0105df3 <strcmp+0x11>
		p++, q++;
f0105ded:	83 c1 01             	add    $0x1,%ecx
f0105df0:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0105df3:	0f b6 01             	movzbl (%ecx),%eax
f0105df6:	84 c0                	test   %al,%al
f0105df8:	74 04                	je     f0105dfe <strcmp+0x1c>
f0105dfa:	3a 02                	cmp    (%edx),%al
f0105dfc:	74 ef                	je     f0105ded <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105dfe:	0f b6 c0             	movzbl %al,%eax
f0105e01:	0f b6 12             	movzbl (%edx),%edx
f0105e04:	29 d0                	sub    %edx,%eax
}
f0105e06:	5d                   	pop    %ebp
f0105e07:	c3                   	ret    

f0105e08 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105e08:	55                   	push   %ebp
f0105e09:	89 e5                	mov    %esp,%ebp
f0105e0b:	53                   	push   %ebx
f0105e0c:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e0f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105e12:	89 c3                	mov    %eax,%ebx
f0105e14:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105e17:	eb 06                	jmp    f0105e1f <strncmp+0x17>
		n--, p++, q++;
f0105e19:	83 c0 01             	add    $0x1,%eax
f0105e1c:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105e1f:	39 d8                	cmp    %ebx,%eax
f0105e21:	74 16                	je     f0105e39 <strncmp+0x31>
f0105e23:	0f b6 08             	movzbl (%eax),%ecx
f0105e26:	84 c9                	test   %cl,%cl
f0105e28:	74 04                	je     f0105e2e <strncmp+0x26>
f0105e2a:	3a 0a                	cmp    (%edx),%cl
f0105e2c:	74 eb                	je     f0105e19 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105e2e:	0f b6 00             	movzbl (%eax),%eax
f0105e31:	0f b6 12             	movzbl (%edx),%edx
f0105e34:	29 d0                	sub    %edx,%eax
}
f0105e36:	5b                   	pop    %ebx
f0105e37:	5d                   	pop    %ebp
f0105e38:	c3                   	ret    
		return 0;
f0105e39:	b8 00 00 00 00       	mov    $0x0,%eax
f0105e3e:	eb f6                	jmp    f0105e36 <strncmp+0x2e>

f0105e40 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105e40:	55                   	push   %ebp
f0105e41:	89 e5                	mov    %esp,%ebp
f0105e43:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e46:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105e4a:	0f b6 10             	movzbl (%eax),%edx
f0105e4d:	84 d2                	test   %dl,%dl
f0105e4f:	74 09                	je     f0105e5a <strchr+0x1a>
		if (*s == c)
f0105e51:	38 ca                	cmp    %cl,%dl
f0105e53:	74 0a                	je     f0105e5f <strchr+0x1f>
	for (; *s; s++)
f0105e55:	83 c0 01             	add    $0x1,%eax
f0105e58:	eb f0                	jmp    f0105e4a <strchr+0xa>
			return (char *) s;
	return 0;
f0105e5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105e5f:	5d                   	pop    %ebp
f0105e60:	c3                   	ret    

f0105e61 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105e61:	55                   	push   %ebp
f0105e62:	89 e5                	mov    %esp,%ebp
f0105e64:	8b 45 08             	mov    0x8(%ebp),%eax
f0105e67:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105e6b:	eb 03                	jmp    f0105e70 <strfind+0xf>
f0105e6d:	83 c0 01             	add    $0x1,%eax
f0105e70:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105e73:	38 ca                	cmp    %cl,%dl
f0105e75:	74 04                	je     f0105e7b <strfind+0x1a>
f0105e77:	84 d2                	test   %dl,%dl
f0105e79:	75 f2                	jne    f0105e6d <strfind+0xc>
			break;
	return (char *) s;
}
f0105e7b:	5d                   	pop    %ebp
f0105e7c:	c3                   	ret    

f0105e7d <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105e7d:	55                   	push   %ebp
f0105e7e:	89 e5                	mov    %esp,%ebp
f0105e80:	57                   	push   %edi
f0105e81:	56                   	push   %esi
f0105e82:	53                   	push   %ebx
f0105e83:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105e86:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105e89:	85 c9                	test   %ecx,%ecx
f0105e8b:	74 13                	je     f0105ea0 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105e8d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105e93:	75 05                	jne    f0105e9a <memset+0x1d>
f0105e95:	f6 c1 03             	test   $0x3,%cl
f0105e98:	74 0d                	je     f0105ea7 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105e9a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105e9d:	fc                   	cld    
f0105e9e:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105ea0:	89 f8                	mov    %edi,%eax
f0105ea2:	5b                   	pop    %ebx
f0105ea3:	5e                   	pop    %esi
f0105ea4:	5f                   	pop    %edi
f0105ea5:	5d                   	pop    %ebp
f0105ea6:	c3                   	ret    
		c &= 0xFF;
f0105ea7:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105eab:	89 d3                	mov    %edx,%ebx
f0105ead:	c1 e3 08             	shl    $0x8,%ebx
f0105eb0:	89 d0                	mov    %edx,%eax
f0105eb2:	c1 e0 18             	shl    $0x18,%eax
f0105eb5:	89 d6                	mov    %edx,%esi
f0105eb7:	c1 e6 10             	shl    $0x10,%esi
f0105eba:	09 f0                	or     %esi,%eax
f0105ebc:	09 c2                	or     %eax,%edx
f0105ebe:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0105ec0:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0105ec3:	89 d0                	mov    %edx,%eax
f0105ec5:	fc                   	cld    
f0105ec6:	f3 ab                	rep stos %eax,%es:(%edi)
f0105ec8:	eb d6                	jmp    f0105ea0 <memset+0x23>

f0105eca <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105eca:	55                   	push   %ebp
f0105ecb:	89 e5                	mov    %esp,%ebp
f0105ecd:	57                   	push   %edi
f0105ece:	56                   	push   %esi
f0105ecf:	8b 45 08             	mov    0x8(%ebp),%eax
f0105ed2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105ed5:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0105ed8:	39 c6                	cmp    %eax,%esi
f0105eda:	73 35                	jae    f0105f11 <memmove+0x47>
f0105edc:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105edf:	39 c2                	cmp    %eax,%edx
f0105ee1:	76 2e                	jbe    f0105f11 <memmove+0x47>
		s += n;
		d += n;
f0105ee3:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105ee6:	89 d6                	mov    %edx,%esi
f0105ee8:	09 fe                	or     %edi,%esi
f0105eea:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105ef0:	74 0c                	je     f0105efe <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0105ef2:	83 ef 01             	sub    $0x1,%edi
f0105ef5:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105ef8:	fd                   	std    
f0105ef9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105efb:	fc                   	cld    
f0105efc:	eb 21                	jmp    f0105f1f <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105efe:	f6 c1 03             	test   $0x3,%cl
f0105f01:	75 ef                	jne    f0105ef2 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105f03:	83 ef 04             	sub    $0x4,%edi
f0105f06:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105f09:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105f0c:	fd                   	std    
f0105f0d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105f0f:	eb ea                	jmp    f0105efb <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105f11:	89 f2                	mov    %esi,%edx
f0105f13:	09 c2                	or     %eax,%edx
f0105f15:	f6 c2 03             	test   $0x3,%dl
f0105f18:	74 09                	je     f0105f23 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105f1a:	89 c7                	mov    %eax,%edi
f0105f1c:	fc                   	cld    
f0105f1d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105f1f:	5e                   	pop    %esi
f0105f20:	5f                   	pop    %edi
f0105f21:	5d                   	pop    %ebp
f0105f22:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105f23:	f6 c1 03             	test   $0x3,%cl
f0105f26:	75 f2                	jne    f0105f1a <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105f28:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105f2b:	89 c7                	mov    %eax,%edi
f0105f2d:	fc                   	cld    
f0105f2e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105f30:	eb ed                	jmp    f0105f1f <memmove+0x55>

f0105f32 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105f32:	55                   	push   %ebp
f0105f33:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0105f35:	ff 75 10             	pushl  0x10(%ebp)
f0105f38:	ff 75 0c             	pushl  0xc(%ebp)
f0105f3b:	ff 75 08             	pushl  0x8(%ebp)
f0105f3e:	e8 87 ff ff ff       	call   f0105eca <memmove>
}
f0105f43:	c9                   	leave  
f0105f44:	c3                   	ret    

f0105f45 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0105f45:	55                   	push   %ebp
f0105f46:	89 e5                	mov    %esp,%ebp
f0105f48:	56                   	push   %esi
f0105f49:	53                   	push   %ebx
f0105f4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f4d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105f50:	89 c6                	mov    %eax,%esi
f0105f52:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105f55:	39 f0                	cmp    %esi,%eax
f0105f57:	74 1c                	je     f0105f75 <memcmp+0x30>
		if (*s1 != *s2)
f0105f59:	0f b6 08             	movzbl (%eax),%ecx
f0105f5c:	0f b6 1a             	movzbl (%edx),%ebx
f0105f5f:	38 d9                	cmp    %bl,%cl
f0105f61:	75 08                	jne    f0105f6b <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0105f63:	83 c0 01             	add    $0x1,%eax
f0105f66:	83 c2 01             	add    $0x1,%edx
f0105f69:	eb ea                	jmp    f0105f55 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0105f6b:	0f b6 c1             	movzbl %cl,%eax
f0105f6e:	0f b6 db             	movzbl %bl,%ebx
f0105f71:	29 d8                	sub    %ebx,%eax
f0105f73:	eb 05                	jmp    f0105f7a <memcmp+0x35>
	}

	return 0;
f0105f75:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105f7a:	5b                   	pop    %ebx
f0105f7b:	5e                   	pop    %esi
f0105f7c:	5d                   	pop    %ebp
f0105f7d:	c3                   	ret    

f0105f7e <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105f7e:	55                   	push   %ebp
f0105f7f:	89 e5                	mov    %esp,%ebp
f0105f81:	8b 45 08             	mov    0x8(%ebp),%eax
f0105f84:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105f87:	89 c2                	mov    %eax,%edx
f0105f89:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105f8c:	39 d0                	cmp    %edx,%eax
f0105f8e:	73 09                	jae    f0105f99 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105f90:	38 08                	cmp    %cl,(%eax)
f0105f92:	74 05                	je     f0105f99 <memfind+0x1b>
	for (; s < ends; s++)
f0105f94:	83 c0 01             	add    $0x1,%eax
f0105f97:	eb f3                	jmp    f0105f8c <memfind+0xe>
			break;
	return (void *) s;
}
f0105f99:	5d                   	pop    %ebp
f0105f9a:	c3                   	ret    

f0105f9b <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105f9b:	55                   	push   %ebp
f0105f9c:	89 e5                	mov    %esp,%ebp
f0105f9e:	57                   	push   %edi
f0105f9f:	56                   	push   %esi
f0105fa0:	53                   	push   %ebx
f0105fa1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105fa4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105fa7:	eb 03                	jmp    f0105fac <strtol+0x11>
		s++;
f0105fa9:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105fac:	0f b6 01             	movzbl (%ecx),%eax
f0105faf:	3c 20                	cmp    $0x20,%al
f0105fb1:	74 f6                	je     f0105fa9 <strtol+0xe>
f0105fb3:	3c 09                	cmp    $0x9,%al
f0105fb5:	74 f2                	je     f0105fa9 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0105fb7:	3c 2b                	cmp    $0x2b,%al
f0105fb9:	74 2e                	je     f0105fe9 <strtol+0x4e>
	int neg = 0;
f0105fbb:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105fc0:	3c 2d                	cmp    $0x2d,%al
f0105fc2:	74 2f                	je     f0105ff3 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105fc4:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105fca:	75 05                	jne    f0105fd1 <strtol+0x36>
f0105fcc:	80 39 30             	cmpb   $0x30,(%ecx)
f0105fcf:	74 2c                	je     f0105ffd <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105fd1:	85 db                	test   %ebx,%ebx
f0105fd3:	75 0a                	jne    f0105fdf <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105fd5:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0105fda:	80 39 30             	cmpb   $0x30,(%ecx)
f0105fdd:	74 28                	je     f0106007 <strtol+0x6c>
		base = 10;
f0105fdf:	b8 00 00 00 00       	mov    $0x0,%eax
f0105fe4:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105fe7:	eb 50                	jmp    f0106039 <strtol+0x9e>
		s++;
f0105fe9:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105fec:	bf 00 00 00 00       	mov    $0x0,%edi
f0105ff1:	eb d1                	jmp    f0105fc4 <strtol+0x29>
		s++, neg = 1;
f0105ff3:	83 c1 01             	add    $0x1,%ecx
f0105ff6:	bf 01 00 00 00       	mov    $0x1,%edi
f0105ffb:	eb c7                	jmp    f0105fc4 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105ffd:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0106001:	74 0e                	je     f0106011 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0106003:	85 db                	test   %ebx,%ebx
f0106005:	75 d8                	jne    f0105fdf <strtol+0x44>
		s++, base = 8;
f0106007:	83 c1 01             	add    $0x1,%ecx
f010600a:	bb 08 00 00 00       	mov    $0x8,%ebx
f010600f:	eb ce                	jmp    f0105fdf <strtol+0x44>
		s += 2, base = 16;
f0106011:	83 c1 02             	add    $0x2,%ecx
f0106014:	bb 10 00 00 00       	mov    $0x10,%ebx
f0106019:	eb c4                	jmp    f0105fdf <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010601b:	8d 72 9f             	lea    -0x61(%edx),%esi
f010601e:	89 f3                	mov    %esi,%ebx
f0106020:	80 fb 19             	cmp    $0x19,%bl
f0106023:	77 29                	ja     f010604e <strtol+0xb3>
			dig = *s - 'a' + 10;
f0106025:	0f be d2             	movsbl %dl,%edx
f0106028:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010602b:	3b 55 10             	cmp    0x10(%ebp),%edx
f010602e:	7d 30                	jge    f0106060 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0106030:	83 c1 01             	add    $0x1,%ecx
f0106033:	0f af 45 10          	imul   0x10(%ebp),%eax
f0106037:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0106039:	0f b6 11             	movzbl (%ecx),%edx
f010603c:	8d 72 d0             	lea    -0x30(%edx),%esi
f010603f:	89 f3                	mov    %esi,%ebx
f0106041:	80 fb 09             	cmp    $0x9,%bl
f0106044:	77 d5                	ja     f010601b <strtol+0x80>
			dig = *s - '0';
f0106046:	0f be d2             	movsbl %dl,%edx
f0106049:	83 ea 30             	sub    $0x30,%edx
f010604c:	eb dd                	jmp    f010602b <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f010604e:	8d 72 bf             	lea    -0x41(%edx),%esi
f0106051:	89 f3                	mov    %esi,%ebx
f0106053:	80 fb 19             	cmp    $0x19,%bl
f0106056:	77 08                	ja     f0106060 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0106058:	0f be d2             	movsbl %dl,%edx
f010605b:	83 ea 37             	sub    $0x37,%edx
f010605e:	eb cb                	jmp    f010602b <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0106060:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0106064:	74 05                	je     f010606b <strtol+0xd0>
		*endptr = (char *) s;
f0106066:	8b 75 0c             	mov    0xc(%ebp),%esi
f0106069:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010606b:	89 c2                	mov    %eax,%edx
f010606d:	f7 da                	neg    %edx
f010606f:	85 ff                	test   %edi,%edi
f0106071:	0f 45 c2             	cmovne %edx,%eax
}
f0106074:	5b                   	pop    %ebx
f0106075:	5e                   	pop    %esi
f0106076:	5f                   	pop    %edi
f0106077:	5d                   	pop    %ebp
f0106078:	c3                   	ret    
f0106079:	66 90                	xchg   %ax,%ax
f010607b:	90                   	nop

f010607c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010607c:	fa                   	cli    

	xorw    %ax, %ax
f010607d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010607f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0106081:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0106083:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0106085:	0f 01 16             	lgdtl  (%esi)
f0106088:	74 70                	je     f01060fa <mpsearch1+0x3>
	movl    %cr0, %eax
f010608a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010608d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0106091:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0106094:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010609a:	08 00                	or     %al,(%eax)

f010609c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010609c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01060a0:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01060a2:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01060a4:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01060a6:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01060aa:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01060ac:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01060ae:	b8 00 10 12 00       	mov    $0x121000,%eax
	movl    %eax, %cr3
f01060b3:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01060b6:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01060b9:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01060be:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01060c1:	8b 25 84 6e 21 f0    	mov    0xf0216e84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01060c7:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01060cc:	b8 b4 01 10 f0       	mov    $0xf01001b4,%eax
	call    *%eax
f01060d1:	ff d0                	call   *%eax

f01060d3 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01060d3:	eb fe                	jmp    f01060d3 <spin>
f01060d5:	8d 76 00             	lea    0x0(%esi),%esi

f01060d8 <gdt>:
	...
f01060e0:	ff                   	(bad)  
f01060e1:	ff 00                	incl   (%eax)
f01060e3:	00 00                	add    %al,(%eax)
f01060e5:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01060ec:	00                   	.byte 0x0
f01060ed:	92                   	xchg   %eax,%edx
f01060ee:	cf                   	iret   
	...

f01060f0 <gdtdesc>:
f01060f0:	17                   	pop    %ss
f01060f1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01060f6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01060f6:	90                   	nop

f01060f7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01060f7:	55                   	push   %ebp
f01060f8:	89 e5                	mov    %esp,%ebp
f01060fa:	57                   	push   %edi
f01060fb:	56                   	push   %esi
f01060fc:	53                   	push   %ebx
f01060fd:	83 ec 0c             	sub    $0xc,%esp
	if (PGNUM(pa) >= npages)
f0106100:	8b 0d 88 6e 21 f0    	mov    0xf0216e88,%ecx
f0106106:	89 c3                	mov    %eax,%ebx
f0106108:	c1 eb 0c             	shr    $0xc,%ebx
f010610b:	39 cb                	cmp    %ecx,%ebx
f010610d:	73 1a                	jae    f0106129 <mpsearch1+0x32>
	return (void *)(pa + KERNBASE);
f010610f:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0106115:	8d 34 02             	lea    (%edx,%eax,1),%esi
	if (PGNUM(pa) >= npages)
f0106118:	89 f0                	mov    %esi,%eax
f010611a:	c1 e8 0c             	shr    $0xc,%eax
f010611d:	39 c8                	cmp    %ecx,%eax
f010611f:	73 1a                	jae    f010613b <mpsearch1+0x44>
	return (void *)(pa + KERNBASE);
f0106121:	81 ee 00 00 00 10    	sub    $0x10000000,%esi

	for (; mp < end; mp++)
f0106127:	eb 27                	jmp    f0106150 <mpsearch1+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106129:	50                   	push   %eax
f010612a:	68 04 6b 10 f0       	push   $0xf0106b04
f010612f:	6a 57                	push   $0x57
f0106131:	68 1d 8a 10 f0       	push   $0xf0108a1d
f0106136:	e8 05 9f ff ff       	call   f0100040 <_panic>
f010613b:	56                   	push   %esi
f010613c:	68 04 6b 10 f0       	push   $0xf0106b04
f0106141:	6a 57                	push   $0x57
f0106143:	68 1d 8a 10 f0       	push   $0xf0108a1d
f0106148:	e8 f3 9e ff ff       	call   f0100040 <_panic>
f010614d:	83 c3 10             	add    $0x10,%ebx
f0106150:	39 f3                	cmp    %esi,%ebx
f0106152:	73 2e                	jae    f0106182 <mpsearch1+0x8b>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0106154:	83 ec 04             	sub    $0x4,%esp
f0106157:	6a 04                	push   $0x4
f0106159:	68 2d 8a 10 f0       	push   $0xf0108a2d
f010615e:	53                   	push   %ebx
f010615f:	e8 e1 fd ff ff       	call   f0105f45 <memcmp>
f0106164:	83 c4 10             	add    $0x10,%esp
f0106167:	85 c0                	test   %eax,%eax
f0106169:	75 e2                	jne    f010614d <mpsearch1+0x56>
f010616b:	89 da                	mov    %ebx,%edx
f010616d:	8d 7b 10             	lea    0x10(%ebx),%edi
		sum += ((uint8_t *)addr)[i];
f0106170:	0f b6 0a             	movzbl (%edx),%ecx
f0106173:	01 c8                	add    %ecx,%eax
f0106175:	83 c2 01             	add    $0x1,%edx
	for (i = 0; i < len; i++)
f0106178:	39 fa                	cmp    %edi,%edx
f010617a:	75 f4                	jne    f0106170 <mpsearch1+0x79>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010617c:	84 c0                	test   %al,%al
f010617e:	75 cd                	jne    f010614d <mpsearch1+0x56>
f0106180:	eb 05                	jmp    f0106187 <mpsearch1+0x90>
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0106182:	bb 00 00 00 00       	mov    $0x0,%ebx
}
f0106187:	89 d8                	mov    %ebx,%eax
f0106189:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010618c:	5b                   	pop    %ebx
f010618d:	5e                   	pop    %esi
f010618e:	5f                   	pop    %edi
f010618f:	5d                   	pop    %ebp
f0106190:	c3                   	ret    

f0106191 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0106191:	55                   	push   %ebp
f0106192:	89 e5                	mov    %esp,%ebp
f0106194:	57                   	push   %edi
f0106195:	56                   	push   %esi
f0106196:	53                   	push   %ebx
f0106197:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f010619a:	c7 05 c0 73 21 f0 20 	movl   $0xf0217020,0xf02173c0
f01061a1:	70 21 f0 
	if (PGNUM(pa) >= npages)
f01061a4:	83 3d 88 6e 21 f0 00 	cmpl   $0x0,0xf0216e88
f01061ab:	0f 84 87 00 00 00    	je     f0106238 <mp_init+0xa7>
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01061b1:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01061b8:	85 c0                	test   %eax,%eax
f01061ba:	0f 84 8e 00 00 00    	je     f010624e <mp_init+0xbd>
		p <<= 4;	// Translate from segment to PA
f01061c0:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f01061c3:	ba 00 04 00 00       	mov    $0x400,%edx
f01061c8:	e8 2a ff ff ff       	call   f01060f7 <mpsearch1>
f01061cd:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01061d0:	85 c0                	test   %eax,%eax
f01061d2:	0f 84 9a 00 00 00    	je     f0106272 <mp_init+0xe1>
	if (mp->physaddr == 0 || mp->type != 0) {
f01061d8:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f01061db:	8b 41 04             	mov    0x4(%ecx),%eax
f01061de:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01061e1:	85 c0                	test   %eax,%eax
f01061e3:	0f 84 a8 00 00 00    	je     f0106291 <mp_init+0x100>
f01061e9:	80 79 0b 00          	cmpb   $0x0,0xb(%ecx)
f01061ed:	0f 85 9e 00 00 00    	jne    f0106291 <mp_init+0x100>
f01061f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01061f6:	c1 e8 0c             	shr    $0xc,%eax
f01061f9:	3b 05 88 6e 21 f0    	cmp    0xf0216e88,%eax
f01061ff:	0f 83 a1 00 00 00    	jae    f01062a6 <mp_init+0x115>
	return (void *)(pa + KERNBASE);
f0106205:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0106208:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f010620e:	89 de                	mov    %ebx,%esi
	if (memcmp(conf, "PCMP", 4) != 0) {
f0106210:	83 ec 04             	sub    $0x4,%esp
f0106213:	6a 04                	push   $0x4
f0106215:	68 32 8a 10 f0       	push   $0xf0108a32
f010621a:	53                   	push   %ebx
f010621b:	e8 25 fd ff ff       	call   f0105f45 <memcmp>
f0106220:	83 c4 10             	add    $0x10,%esp
f0106223:	85 c0                	test   %eax,%eax
f0106225:	0f 85 92 00 00 00    	jne    f01062bd <mp_init+0x12c>
f010622b:	0f b7 7b 04          	movzwl 0x4(%ebx),%edi
f010622f:	01 df                	add    %ebx,%edi
	sum = 0;
f0106231:	89 c2                	mov    %eax,%edx
f0106233:	e9 a2 00 00 00       	jmp    f01062da <mp_init+0x149>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0106238:	68 00 04 00 00       	push   $0x400
f010623d:	68 04 6b 10 f0       	push   $0xf0106b04
f0106242:	6a 6f                	push   $0x6f
f0106244:	68 1d 8a 10 f0       	push   $0xf0108a1d
f0106249:	e8 f2 9d ff ff       	call   f0100040 <_panic>
		p = *(uint16_t *) (bda + 0x13) * 1024;
f010624e:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0106255:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0106258:	2d 00 04 00 00       	sub    $0x400,%eax
f010625d:	ba 00 04 00 00       	mov    $0x400,%edx
f0106262:	e8 90 fe ff ff       	call   f01060f7 <mpsearch1>
f0106267:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010626a:	85 c0                	test   %eax,%eax
f010626c:	0f 85 66 ff ff ff    	jne    f01061d8 <mp_init+0x47>
	return mpsearch1(0xF0000, 0x10000);
f0106272:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106277:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010627c:	e8 76 fe ff ff       	call   f01060f7 <mpsearch1>
f0106281:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if ((mp = mpsearch()) == 0)
f0106284:	85 c0                	test   %eax,%eax
f0106286:	0f 85 4c ff ff ff    	jne    f01061d8 <mp_init+0x47>
f010628c:	e9 a8 01 00 00       	jmp    f0106439 <mp_init+0x2a8>
		cprintf("SMP: Default configurations not implemented\n");
f0106291:	83 ec 0c             	sub    $0xc,%esp
f0106294:	68 90 88 10 f0       	push   $0xf0108890
f0106299:	e8 cd da ff ff       	call   f0103d6b <cprintf>
f010629e:	83 c4 10             	add    $0x10,%esp
f01062a1:	e9 93 01 00 00       	jmp    f0106439 <mp_init+0x2a8>
f01062a6:	ff 75 e4             	pushl  -0x1c(%ebp)
f01062a9:	68 04 6b 10 f0       	push   $0xf0106b04
f01062ae:	68 90 00 00 00       	push   $0x90
f01062b3:	68 1d 8a 10 f0       	push   $0xf0108a1d
f01062b8:	e8 83 9d ff ff       	call   f0100040 <_panic>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01062bd:	83 ec 0c             	sub    $0xc,%esp
f01062c0:	68 c0 88 10 f0       	push   $0xf01088c0
f01062c5:	e8 a1 da ff ff       	call   f0103d6b <cprintf>
f01062ca:	83 c4 10             	add    $0x10,%esp
f01062cd:	e9 67 01 00 00       	jmp    f0106439 <mp_init+0x2a8>
		sum += ((uint8_t *)addr)[i];
f01062d2:	0f b6 0b             	movzbl (%ebx),%ecx
f01062d5:	01 ca                	add    %ecx,%edx
f01062d7:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f01062da:	39 fb                	cmp    %edi,%ebx
f01062dc:	75 f4                	jne    f01062d2 <mp_init+0x141>
	if (sum(conf, conf->length) != 0) {
f01062de:	84 d2                	test   %dl,%dl
f01062e0:	75 16                	jne    f01062f8 <mp_init+0x167>
	if (conf->version != 1 && conf->version != 4) {
f01062e2:	0f b6 56 06          	movzbl 0x6(%esi),%edx
f01062e6:	80 fa 01             	cmp    $0x1,%dl
f01062e9:	74 05                	je     f01062f0 <mp_init+0x15f>
f01062eb:	80 fa 04             	cmp    $0x4,%dl
f01062ee:	75 1d                	jne    f010630d <mp_init+0x17c>
f01062f0:	0f b7 4e 28          	movzwl 0x28(%esi),%ecx
f01062f4:	01 d9                	add    %ebx,%ecx
f01062f6:	eb 36                	jmp    f010632e <mp_init+0x19d>
		cprintf("SMP: Bad MP configuration checksum\n");
f01062f8:	83 ec 0c             	sub    $0xc,%esp
f01062fb:	68 f4 88 10 f0       	push   $0xf01088f4
f0106300:	e8 66 da ff ff       	call   f0103d6b <cprintf>
f0106305:	83 c4 10             	add    $0x10,%esp
f0106308:	e9 2c 01 00 00       	jmp    f0106439 <mp_init+0x2a8>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f010630d:	83 ec 08             	sub    $0x8,%esp
f0106310:	0f b6 d2             	movzbl %dl,%edx
f0106313:	52                   	push   %edx
f0106314:	68 18 89 10 f0       	push   $0xf0108918
f0106319:	e8 4d da ff ff       	call   f0103d6b <cprintf>
f010631e:	83 c4 10             	add    $0x10,%esp
f0106321:	e9 13 01 00 00       	jmp    f0106439 <mp_init+0x2a8>
		sum += ((uint8_t *)addr)[i];
f0106326:	0f b6 13             	movzbl (%ebx),%edx
f0106329:	01 d0                	add    %edx,%eax
f010632b:	83 c3 01             	add    $0x1,%ebx
	for (i = 0; i < len; i++)
f010632e:	39 d9                	cmp    %ebx,%ecx
f0106330:	75 f4                	jne    f0106326 <mp_init+0x195>
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0106332:	02 46 2a             	add    0x2a(%esi),%al
f0106335:	75 29                	jne    f0106360 <mp_init+0x1cf>
	if ((conf = mpconfig(&mp)) == 0)
f0106337:	81 7d e4 00 00 00 10 	cmpl   $0x10000000,-0x1c(%ebp)
f010633e:	0f 84 f5 00 00 00    	je     f0106439 <mp_init+0x2a8>
		return;
	ismp = 1;
f0106344:	c7 05 00 70 21 f0 01 	movl   $0x1,0xf0217000
f010634b:	00 00 00 
	lapicaddr = conf->lapicaddr;
f010634e:	8b 46 24             	mov    0x24(%esi),%eax
f0106351:	a3 00 80 25 f0       	mov    %eax,0xf0258000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0106356:	8d 7e 2c             	lea    0x2c(%esi),%edi
f0106359:	bb 00 00 00 00       	mov    $0x0,%ebx
f010635e:	eb 4d                	jmp    f01063ad <mp_init+0x21c>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0106360:	83 ec 0c             	sub    $0xc,%esp
f0106363:	68 38 89 10 f0       	push   $0xf0108938
f0106368:	e8 fe d9 ff ff       	call   f0103d6b <cprintf>
f010636d:	83 c4 10             	add    $0x10,%esp
f0106370:	e9 c4 00 00 00       	jmp    f0106439 <mp_init+0x2a8>
		switch (*p) {
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0106375:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0106379:	74 11                	je     f010638c <mp_init+0x1fb>
				bootcpu = &cpus[ncpu];
f010637b:	6b 05 c4 73 21 f0 74 	imul   $0x74,0xf02173c4,%eax
f0106382:	05 20 70 21 f0       	add    $0xf0217020,%eax
f0106387:	a3 c0 73 21 f0       	mov    %eax,0xf02173c0
			if (ncpu < NCPU) {
f010638c:	a1 c4 73 21 f0       	mov    0xf02173c4,%eax
f0106391:	83 f8 07             	cmp    $0x7,%eax
f0106394:	7f 2f                	jg     f01063c5 <mp_init+0x234>
				cpus[ncpu].cpu_id = ncpu;
f0106396:	6b d0 74             	imul   $0x74,%eax,%edx
f0106399:	88 82 20 70 21 f0    	mov    %al,-0xfde8fe0(%edx)
				ncpu++;
f010639f:	83 c0 01             	add    $0x1,%eax
f01063a2:	a3 c4 73 21 f0       	mov    %eax,0xf02173c4
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01063a7:	83 c7 14             	add    $0x14,%edi
	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f01063aa:	83 c3 01             	add    $0x1,%ebx
f01063ad:	0f b7 46 22          	movzwl 0x22(%esi),%eax
f01063b1:	39 d8                	cmp    %ebx,%eax
f01063b3:	76 4b                	jbe    f0106400 <mp_init+0x26f>
		switch (*p) {
f01063b5:	0f b6 07             	movzbl (%edi),%eax
f01063b8:	84 c0                	test   %al,%al
f01063ba:	74 b9                	je     f0106375 <mp_init+0x1e4>
f01063bc:	3c 04                	cmp    $0x4,%al
f01063be:	77 1c                	ja     f01063dc <mp_init+0x24b>
			continue;
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01063c0:	83 c7 08             	add    $0x8,%edi
			continue;
f01063c3:	eb e5                	jmp    f01063aa <mp_init+0x219>
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01063c5:	83 ec 08             	sub    $0x8,%esp
f01063c8:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01063cc:	50                   	push   %eax
f01063cd:	68 68 89 10 f0       	push   $0xf0108968
f01063d2:	e8 94 d9 ff ff       	call   f0103d6b <cprintf>
f01063d7:	83 c4 10             	add    $0x10,%esp
f01063da:	eb cb                	jmp    f01063a7 <mp_init+0x216>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01063dc:	83 ec 08             	sub    $0x8,%esp
		switch (*p) {
f01063df:	0f b6 c0             	movzbl %al,%eax
			cprintf("mpinit: unknown config type %x\n", *p);
f01063e2:	50                   	push   %eax
f01063e3:	68 90 89 10 f0       	push   $0xf0108990
f01063e8:	e8 7e d9 ff ff       	call   f0103d6b <cprintf>
			ismp = 0;
f01063ed:	c7 05 00 70 21 f0 00 	movl   $0x0,0xf0217000
f01063f4:	00 00 00 
			i = conf->entry;
f01063f7:	0f b7 5e 22          	movzwl 0x22(%esi),%ebx
f01063fb:	83 c4 10             	add    $0x10,%esp
f01063fe:	eb aa                	jmp    f01063aa <mp_init+0x219>
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0106400:	a1 c0 73 21 f0       	mov    0xf02173c0,%eax
f0106405:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f010640c:	83 3d 00 70 21 f0 00 	cmpl   $0x0,0xf0217000
f0106413:	75 2c                	jne    f0106441 <mp_init+0x2b0>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0106415:	c7 05 c4 73 21 f0 01 	movl   $0x1,0xf02173c4
f010641c:	00 00 00 
		lapicaddr = 0;
f010641f:	c7 05 00 80 25 f0 00 	movl   $0x0,0xf0258000
f0106426:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0106429:	83 ec 0c             	sub    $0xc,%esp
f010642c:	68 b0 89 10 f0       	push   $0xf01089b0
f0106431:	e8 35 d9 ff ff       	call   f0103d6b <cprintf>
		return;
f0106436:	83 c4 10             	add    $0x10,%esp
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
	}
}
f0106439:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010643c:	5b                   	pop    %ebx
f010643d:	5e                   	pop    %esi
f010643e:	5f                   	pop    %edi
f010643f:	5d                   	pop    %ebp
f0106440:	c3                   	ret    
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0106441:	83 ec 04             	sub    $0x4,%esp
f0106444:	ff 35 c4 73 21 f0    	pushl  0xf02173c4
f010644a:	0f b6 00             	movzbl (%eax),%eax
f010644d:	50                   	push   %eax
f010644e:	68 37 8a 10 f0       	push   $0xf0108a37
f0106453:	e8 13 d9 ff ff       	call   f0103d6b <cprintf>
	if (mp->imcrp) {
f0106458:	83 c4 10             	add    $0x10,%esp
f010645b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010645e:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0106462:	74 d5                	je     f0106439 <mp_init+0x2a8>
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0106464:	83 ec 0c             	sub    $0xc,%esp
f0106467:	68 dc 89 10 f0       	push   $0xf01089dc
f010646c:	e8 fa d8 ff ff       	call   f0103d6b <cprintf>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106471:	b8 70 00 00 00       	mov    $0x70,%eax
f0106476:	ba 22 00 00 00       	mov    $0x22,%edx
f010647b:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010647c:	ba 23 00 00 00       	mov    $0x23,%edx
f0106481:	ec                   	in     (%dx),%al
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0106482:	83 c8 01             	or     $0x1,%eax
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0106485:	ee                   	out    %al,(%dx)
f0106486:	83 c4 10             	add    $0x10,%esp
f0106489:	eb ae                	jmp    f0106439 <mp_init+0x2a8>

f010648b <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f010648b:	55                   	push   %ebp
f010648c:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f010648e:	8b 0d 04 80 25 f0    	mov    0xf0258004,%ecx
f0106494:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0106497:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0106499:	a1 04 80 25 f0       	mov    0xf0258004,%eax
f010649e:	8b 40 20             	mov    0x20(%eax),%eax
}
f01064a1:	5d                   	pop    %ebp
f01064a2:	c3                   	ret    

f01064a3 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01064a3:	55                   	push   %ebp
f01064a4:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01064a6:	8b 15 04 80 25 f0    	mov    0xf0258004,%edx
		return lapic[ID] >> 24;
	return 0;
f01064ac:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lapic)
f01064b1:	85 d2                	test   %edx,%edx
f01064b3:	74 06                	je     f01064bb <cpunum+0x18>
		return lapic[ID] >> 24;
f01064b5:	8b 42 20             	mov    0x20(%edx),%eax
f01064b8:	c1 e8 18             	shr    $0x18,%eax
}
f01064bb:	5d                   	pop    %ebp
f01064bc:	c3                   	ret    

f01064bd <lapic_init>:
	if (!lapicaddr)
f01064bd:	a1 00 80 25 f0       	mov    0xf0258000,%eax
f01064c2:	85 c0                	test   %eax,%eax
f01064c4:	75 02                	jne    f01064c8 <lapic_init+0xb>
f01064c6:	f3 c3                	repz ret 
{
f01064c8:	55                   	push   %ebp
f01064c9:	89 e5                	mov    %esp,%ebp
f01064cb:	83 ec 10             	sub    $0x10,%esp
	lapic = mmio_map_region(lapicaddr, 4096);
f01064ce:	68 00 10 00 00       	push   $0x1000
f01064d3:	50                   	push   %eax
f01064d4:	e8 76 b2 ff ff       	call   f010174f <mmio_map_region>
f01064d9:	a3 04 80 25 f0       	mov    %eax,0xf0258004
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f01064de:	ba 27 01 00 00       	mov    $0x127,%edx
f01064e3:	b8 3c 00 00 00       	mov    $0x3c,%eax
f01064e8:	e8 9e ff ff ff       	call   f010648b <lapicw>
	lapicw(TDCR, X1);
f01064ed:	ba 0b 00 00 00       	mov    $0xb,%edx
f01064f2:	b8 f8 00 00 00       	mov    $0xf8,%eax
f01064f7:	e8 8f ff ff ff       	call   f010648b <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01064fc:	ba 20 00 02 00       	mov    $0x20020,%edx
f0106501:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0106506:	e8 80 ff ff ff       	call   f010648b <lapicw>
	lapicw(TICR, 10000000); 
f010650b:	ba 80 96 98 00       	mov    $0x989680,%edx
f0106510:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0106515:	e8 71 ff ff ff       	call   f010648b <lapicw>
	if (thiscpu != bootcpu)
f010651a:	e8 84 ff ff ff       	call   f01064a3 <cpunum>
f010651f:	6b c0 74             	imul   $0x74,%eax,%eax
f0106522:	05 20 70 21 f0       	add    $0xf0217020,%eax
f0106527:	83 c4 10             	add    $0x10,%esp
f010652a:	39 05 c0 73 21 f0    	cmp    %eax,0xf02173c0
f0106530:	74 0f                	je     f0106541 <lapic_init+0x84>
		lapicw(LINT0, MASKED);
f0106532:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106537:	b8 d4 00 00 00       	mov    $0xd4,%eax
f010653c:	e8 4a ff ff ff       	call   f010648b <lapicw>
	lapicw(LINT1, MASKED);
f0106541:	ba 00 00 01 00       	mov    $0x10000,%edx
f0106546:	b8 d8 00 00 00       	mov    $0xd8,%eax
f010654b:	e8 3b ff ff ff       	call   f010648b <lapicw>
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0106550:	a1 04 80 25 f0       	mov    0xf0258004,%eax
f0106555:	8b 40 30             	mov    0x30(%eax),%eax
f0106558:	c1 e8 10             	shr    $0x10,%eax
f010655b:	3c 03                	cmp    $0x3,%al
f010655d:	77 7c                	ja     f01065db <lapic_init+0x11e>
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f010655f:	ba 33 00 00 00       	mov    $0x33,%edx
f0106564:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0106569:	e8 1d ff ff ff       	call   f010648b <lapicw>
	lapicw(ESR, 0);
f010656e:	ba 00 00 00 00       	mov    $0x0,%edx
f0106573:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106578:	e8 0e ff ff ff       	call   f010648b <lapicw>
	lapicw(ESR, 0);
f010657d:	ba 00 00 00 00       	mov    $0x0,%edx
f0106582:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0106587:	e8 ff fe ff ff       	call   f010648b <lapicw>
	lapicw(EOI, 0);
f010658c:	ba 00 00 00 00       	mov    $0x0,%edx
f0106591:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106596:	e8 f0 fe ff ff       	call   f010648b <lapicw>
	lapicw(ICRHI, 0);
f010659b:	ba 00 00 00 00       	mov    $0x0,%edx
f01065a0:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01065a5:	e8 e1 fe ff ff       	call   f010648b <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01065aa:	ba 00 85 08 00       	mov    $0x88500,%edx
f01065af:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01065b4:	e8 d2 fe ff ff       	call   f010648b <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01065b9:	8b 15 04 80 25 f0    	mov    0xf0258004,%edx
f01065bf:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01065c5:	f6 c4 10             	test   $0x10,%ah
f01065c8:	75 f5                	jne    f01065bf <lapic_init+0x102>
	lapicw(TPR, 0);
f01065ca:	ba 00 00 00 00       	mov    $0x0,%edx
f01065cf:	b8 20 00 00 00       	mov    $0x20,%eax
f01065d4:	e8 b2 fe ff ff       	call   f010648b <lapicw>
}
f01065d9:	c9                   	leave  
f01065da:	c3                   	ret    
		lapicw(PCINT, MASKED);
f01065db:	ba 00 00 01 00       	mov    $0x10000,%edx
f01065e0:	b8 d0 00 00 00       	mov    $0xd0,%eax
f01065e5:	e8 a1 fe ff ff       	call   f010648b <lapicw>
f01065ea:	e9 70 ff ff ff       	jmp    f010655f <lapic_init+0xa2>

f01065ef <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f01065ef:	83 3d 04 80 25 f0 00 	cmpl   $0x0,0xf0258004
f01065f6:	74 14                	je     f010660c <lapic_eoi+0x1d>
{
f01065f8:	55                   	push   %ebp
f01065f9:	89 e5                	mov    %esp,%ebp
		lapicw(EOI, 0);
f01065fb:	ba 00 00 00 00       	mov    $0x0,%edx
f0106600:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0106605:	e8 81 fe ff ff       	call   f010648b <lapicw>
}
f010660a:	5d                   	pop    %ebp
f010660b:	c3                   	ret    
f010660c:	f3 c3                	repz ret 

f010660e <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f010660e:	55                   	push   %ebp
f010660f:	89 e5                	mov    %esp,%ebp
f0106611:	56                   	push   %esi
f0106612:	53                   	push   %ebx
f0106613:	8b 75 08             	mov    0x8(%ebp),%esi
f0106616:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0106619:	b8 0f 00 00 00       	mov    $0xf,%eax
f010661e:	ba 70 00 00 00       	mov    $0x70,%edx
f0106623:	ee                   	out    %al,(%dx)
f0106624:	b8 0a 00 00 00       	mov    $0xa,%eax
f0106629:	ba 71 00 00 00       	mov    $0x71,%edx
f010662e:	ee                   	out    %al,(%dx)
	if (PGNUM(pa) >= npages)
f010662f:	83 3d 88 6e 21 f0 00 	cmpl   $0x0,0xf0216e88
f0106636:	74 7e                	je     f01066b6 <lapic_startap+0xa8>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0106638:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f010663f:	00 00 
	wrv[1] = addr >> 4;
f0106641:	89 d8                	mov    %ebx,%eax
f0106643:	c1 e8 04             	shr    $0x4,%eax
f0106646:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f010664c:	c1 e6 18             	shl    $0x18,%esi
f010664f:	89 f2                	mov    %esi,%edx
f0106651:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106656:	e8 30 fe ff ff       	call   f010648b <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f010665b:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0106660:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106665:	e8 21 fe ff ff       	call   f010648b <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f010666a:	ba 00 85 00 00       	mov    $0x8500,%edx
f010666f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106674:	e8 12 fe ff ff       	call   f010648b <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106679:	c1 eb 0c             	shr    $0xc,%ebx
f010667c:	80 cf 06             	or     $0x6,%bh
		lapicw(ICRHI, apicid << 24);
f010667f:	89 f2                	mov    %esi,%edx
f0106681:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0106686:	e8 00 fe ff ff       	call   f010648b <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f010668b:	89 da                	mov    %ebx,%edx
f010668d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106692:	e8 f4 fd ff ff       	call   f010648b <lapicw>
		lapicw(ICRHI, apicid << 24);
f0106697:	89 f2                	mov    %esi,%edx
f0106699:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010669e:	e8 e8 fd ff ff       	call   f010648b <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01066a3:	89 da                	mov    %ebx,%edx
f01066a5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01066aa:	e8 dc fd ff ff       	call   f010648b <lapicw>
		microdelay(200);
	}
}
f01066af:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01066b2:	5b                   	pop    %ebx
f01066b3:	5e                   	pop    %esi
f01066b4:	5d                   	pop    %ebp
f01066b5:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01066b6:	68 67 04 00 00       	push   $0x467
f01066bb:	68 04 6b 10 f0       	push   $0xf0106b04
f01066c0:	68 98 00 00 00       	push   $0x98
f01066c5:	68 54 8a 10 f0       	push   $0xf0108a54
f01066ca:	e8 71 99 ff ff       	call   f0100040 <_panic>

f01066cf <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01066cf:	55                   	push   %ebp
f01066d0:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01066d2:	8b 55 08             	mov    0x8(%ebp),%edx
f01066d5:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01066db:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01066e0:	e8 a6 fd ff ff       	call   f010648b <lapicw>
	while (lapic[ICRLO] & DELIVS)
f01066e5:	8b 15 04 80 25 f0    	mov    0xf0258004,%edx
f01066eb:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01066f1:	f6 c4 10             	test   $0x10,%ah
f01066f4:	75 f5                	jne    f01066eb <lapic_ipi+0x1c>
		;
}
f01066f6:	5d                   	pop    %ebp
f01066f7:	c3                   	ret    

f01066f8 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f01066f8:	55                   	push   %ebp
f01066f9:	89 e5                	mov    %esp,%ebp
f01066fb:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f01066fe:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106704:	8b 55 0c             	mov    0xc(%ebp),%edx
f0106707:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010670a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106711:	5d                   	pop    %ebp
f0106712:	c3                   	ret    

f0106713 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106713:	55                   	push   %ebp
f0106714:	89 e5                	mov    %esp,%ebp
f0106716:	56                   	push   %esi
f0106717:	53                   	push   %ebx
f0106718:	8b 5d 08             	mov    0x8(%ebp),%ebx
	return lock->locked && lock->cpu == thiscpu;
f010671b:	83 3b 00             	cmpl   $0x0,(%ebx)
f010671e:	75 07                	jne    f0106727 <spin_lock+0x14>
	asm volatile("lock; xchgl %0, %1"
f0106720:	ba 01 00 00 00       	mov    $0x1,%edx
f0106725:	eb 34                	jmp    f010675b <spin_lock+0x48>
f0106727:	8b 73 08             	mov    0x8(%ebx),%esi
f010672a:	e8 74 fd ff ff       	call   f01064a3 <cpunum>
f010672f:	6b c0 74             	imul   $0x74,%eax,%eax
f0106732:	05 20 70 21 f0       	add    $0xf0217020,%eax
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0106737:	39 c6                	cmp    %eax,%esi
f0106739:	75 e5                	jne    f0106720 <spin_lock+0xd>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010673b:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010673e:	e8 60 fd ff ff       	call   f01064a3 <cpunum>
f0106743:	83 ec 0c             	sub    $0xc,%esp
f0106746:	53                   	push   %ebx
f0106747:	50                   	push   %eax
f0106748:	68 64 8a 10 f0       	push   $0xf0108a64
f010674d:	6a 41                	push   $0x41
f010674f:	68 c8 8a 10 f0       	push   $0xf0108ac8
f0106754:	e8 e7 98 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0106759:	f3 90                	pause  
f010675b:	89 d0                	mov    %edx,%eax
f010675d:	f0 87 03             	lock xchg %eax,(%ebx)
	while (xchg(&lk->locked, 1) != 0)
f0106760:	85 c0                	test   %eax,%eax
f0106762:	75 f5                	jne    f0106759 <spin_lock+0x46>

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0106764:	e8 3a fd ff ff       	call   f01064a3 <cpunum>
f0106769:	6b c0 74             	imul   $0x74,%eax,%eax
f010676c:	05 20 70 21 f0       	add    $0xf0217020,%eax
f0106771:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0106774:	83 c3 0c             	add    $0xc,%ebx
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0106777:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0106779:	b8 00 00 00 00       	mov    $0x0,%eax
f010677e:	eb 0b                	jmp    f010678b <spin_lock+0x78>
		pcs[i] = ebp[1];          // saved %eip
f0106780:	8b 4a 04             	mov    0x4(%edx),%ecx
f0106783:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0106786:	8b 12                	mov    (%edx),%edx
	for (i = 0; i < 10; i++){
f0106788:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f010678b:	83 f8 09             	cmp    $0x9,%eax
f010678e:	7f 14                	jg     f01067a4 <spin_lock+0x91>
f0106790:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0106796:	77 e8                	ja     f0106780 <spin_lock+0x6d>
f0106798:	eb 0a                	jmp    f01067a4 <spin_lock+0x91>
		pcs[i] = 0;
f010679a:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
	for (; i < 10; i++)
f01067a1:	83 c0 01             	add    $0x1,%eax
f01067a4:	83 f8 09             	cmp    $0x9,%eax
f01067a7:	7e f1                	jle    f010679a <spin_lock+0x87>
#endif
}
f01067a9:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01067ac:	5b                   	pop    %ebx
f01067ad:	5e                   	pop    %esi
f01067ae:	5d                   	pop    %ebp
f01067af:	c3                   	ret    

f01067b0 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01067b0:	55                   	push   %ebp
f01067b1:	89 e5                	mov    %esp,%ebp
f01067b3:	57                   	push   %edi
f01067b4:	56                   	push   %esi
f01067b5:	53                   	push   %ebx
f01067b6:	83 ec 4c             	sub    $0x4c,%esp
f01067b9:	8b 75 08             	mov    0x8(%ebp),%esi
	return lock->locked && lock->cpu == thiscpu;
f01067bc:	83 3e 00             	cmpl   $0x0,(%esi)
f01067bf:	75 35                	jne    f01067f6 <spin_unlock+0x46>
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01067c1:	83 ec 04             	sub    $0x4,%esp
f01067c4:	6a 28                	push   $0x28
f01067c6:	8d 46 0c             	lea    0xc(%esi),%eax
f01067c9:	50                   	push   %eax
f01067ca:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f01067cd:	53                   	push   %ebx
f01067ce:	e8 f7 f6 ff ff       	call   f0105eca <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f01067d3:	8b 46 08             	mov    0x8(%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f01067d6:	0f b6 38             	movzbl (%eax),%edi
f01067d9:	8b 76 04             	mov    0x4(%esi),%esi
f01067dc:	e8 c2 fc ff ff       	call   f01064a3 <cpunum>
f01067e1:	57                   	push   %edi
f01067e2:	56                   	push   %esi
f01067e3:	50                   	push   %eax
f01067e4:	68 90 8a 10 f0       	push   $0xf0108a90
f01067e9:	e8 7d d5 ff ff       	call   f0103d6b <cprintf>
f01067ee:	83 c4 20             	add    $0x20,%esp
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01067f1:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01067f4:	eb 61                	jmp    f0106857 <spin_unlock+0xa7>
	return lock->locked && lock->cpu == thiscpu;
f01067f6:	8b 5e 08             	mov    0x8(%esi),%ebx
f01067f9:	e8 a5 fc ff ff       	call   f01064a3 <cpunum>
f01067fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0106801:	05 20 70 21 f0       	add    $0xf0217020,%eax
	if (!holding(lk)) {
f0106806:	39 c3                	cmp    %eax,%ebx
f0106808:	75 b7                	jne    f01067c1 <spin_unlock+0x11>
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
	}

	lk->pcs[0] = 0;
f010680a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106811:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
	asm volatile("lock; xchgl %0, %1"
f0106818:	b8 00 00 00 00       	mov    $0x0,%eax
f010681d:	f0 87 06             	lock xchg %eax,(%esi)
	// respect to any other instruction which references the same memory.
	// x86 CPUs will not reorder loads/stores across locked instructions
	// (vol 3, 8.2.2). Because xchg() is implemented using asm volatile,
	// gcc will not reorder C statements across the xchg.
	xchg(&lk->locked, 0);
}
f0106820:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0106823:	5b                   	pop    %ebx
f0106824:	5e                   	pop    %esi
f0106825:	5f                   	pop    %edi
f0106826:	5d                   	pop    %ebp
f0106827:	c3                   	ret    
					pcs[i] - info.eip_fn_addr);
f0106828:	8b 06                	mov    (%esi),%eax
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f010682a:	83 ec 04             	sub    $0x4,%esp
f010682d:	89 c2                	mov    %eax,%edx
f010682f:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106832:	52                   	push   %edx
f0106833:	ff 75 b0             	pushl  -0x50(%ebp)
f0106836:	ff 75 b4             	pushl  -0x4c(%ebp)
f0106839:	ff 75 ac             	pushl  -0x54(%ebp)
f010683c:	ff 75 a8             	pushl  -0x58(%ebp)
f010683f:	50                   	push   %eax
f0106840:	68 d8 8a 10 f0       	push   $0xf0108ad8
f0106845:	e8 21 d5 ff ff       	call   f0103d6b <cprintf>
f010684a:	83 c4 20             	add    $0x20,%esp
f010684d:	83 c3 04             	add    $0x4,%ebx
		for (i = 0; i < 10 && pcs[i]; i++) {
f0106850:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0106853:	39 c3                	cmp    %eax,%ebx
f0106855:	74 2d                	je     f0106884 <spin_unlock+0xd4>
f0106857:	89 de                	mov    %ebx,%esi
f0106859:	8b 03                	mov    (%ebx),%eax
f010685b:	85 c0                	test   %eax,%eax
f010685d:	74 25                	je     f0106884 <spin_unlock+0xd4>
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010685f:	83 ec 08             	sub    $0x8,%esp
f0106862:	57                   	push   %edi
f0106863:	50                   	push   %eax
f0106864:	e8 da ea ff ff       	call   f0105343 <debuginfo_eip>
f0106869:	83 c4 10             	add    $0x10,%esp
f010686c:	85 c0                	test   %eax,%eax
f010686e:	79 b8                	jns    f0106828 <spin_unlock+0x78>
				cprintf("  %08x\n", pcs[i]);
f0106870:	83 ec 08             	sub    $0x8,%esp
f0106873:	ff 36                	pushl  (%esi)
f0106875:	68 ef 8a 10 f0       	push   $0xf0108aef
f010687a:	e8 ec d4 ff ff       	call   f0103d6b <cprintf>
f010687f:	83 c4 10             	add    $0x10,%esp
f0106882:	eb c9                	jmp    f010684d <spin_unlock+0x9d>
		panic("spin_unlock");
f0106884:	83 ec 04             	sub    $0x4,%esp
f0106887:	68 f7 8a 10 f0       	push   $0xf0108af7
f010688c:	6a 67                	push   $0x67
f010688e:	68 c8 8a 10 f0       	push   $0xf0108ac8
f0106893:	e8 a8 97 ff ff       	call   f0100040 <_panic>
f0106898:	66 90                	xchg   %ax,%ax
f010689a:	66 90                	xchg   %ax,%ax
f010689c:	66 90                	xchg   %ax,%ax
f010689e:	66 90                	xchg   %ax,%ax

f01068a0 <__udivdi3>:
f01068a0:	55                   	push   %ebp
f01068a1:	57                   	push   %edi
f01068a2:	56                   	push   %esi
f01068a3:	53                   	push   %ebx
f01068a4:	83 ec 1c             	sub    $0x1c,%esp
f01068a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01068ab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01068af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01068b3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01068b7:	85 d2                	test   %edx,%edx
f01068b9:	75 35                	jne    f01068f0 <__udivdi3+0x50>
f01068bb:	39 f3                	cmp    %esi,%ebx
f01068bd:	0f 87 bd 00 00 00    	ja     f0106980 <__udivdi3+0xe0>
f01068c3:	85 db                	test   %ebx,%ebx
f01068c5:	89 d9                	mov    %ebx,%ecx
f01068c7:	75 0b                	jne    f01068d4 <__udivdi3+0x34>
f01068c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01068ce:	31 d2                	xor    %edx,%edx
f01068d0:	f7 f3                	div    %ebx
f01068d2:	89 c1                	mov    %eax,%ecx
f01068d4:	31 d2                	xor    %edx,%edx
f01068d6:	89 f0                	mov    %esi,%eax
f01068d8:	f7 f1                	div    %ecx
f01068da:	89 c6                	mov    %eax,%esi
f01068dc:	89 e8                	mov    %ebp,%eax
f01068de:	89 f7                	mov    %esi,%edi
f01068e0:	f7 f1                	div    %ecx
f01068e2:	89 fa                	mov    %edi,%edx
f01068e4:	83 c4 1c             	add    $0x1c,%esp
f01068e7:	5b                   	pop    %ebx
f01068e8:	5e                   	pop    %esi
f01068e9:	5f                   	pop    %edi
f01068ea:	5d                   	pop    %ebp
f01068eb:	c3                   	ret    
f01068ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01068f0:	39 f2                	cmp    %esi,%edx
f01068f2:	77 7c                	ja     f0106970 <__udivdi3+0xd0>
f01068f4:	0f bd fa             	bsr    %edx,%edi
f01068f7:	83 f7 1f             	xor    $0x1f,%edi
f01068fa:	0f 84 98 00 00 00    	je     f0106998 <__udivdi3+0xf8>
f0106900:	89 f9                	mov    %edi,%ecx
f0106902:	b8 20 00 00 00       	mov    $0x20,%eax
f0106907:	29 f8                	sub    %edi,%eax
f0106909:	d3 e2                	shl    %cl,%edx
f010690b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010690f:	89 c1                	mov    %eax,%ecx
f0106911:	89 da                	mov    %ebx,%edx
f0106913:	d3 ea                	shr    %cl,%edx
f0106915:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0106919:	09 d1                	or     %edx,%ecx
f010691b:	89 f2                	mov    %esi,%edx
f010691d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106921:	89 f9                	mov    %edi,%ecx
f0106923:	d3 e3                	shl    %cl,%ebx
f0106925:	89 c1                	mov    %eax,%ecx
f0106927:	d3 ea                	shr    %cl,%edx
f0106929:	89 f9                	mov    %edi,%ecx
f010692b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010692f:	d3 e6                	shl    %cl,%esi
f0106931:	89 eb                	mov    %ebp,%ebx
f0106933:	89 c1                	mov    %eax,%ecx
f0106935:	d3 eb                	shr    %cl,%ebx
f0106937:	09 de                	or     %ebx,%esi
f0106939:	89 f0                	mov    %esi,%eax
f010693b:	f7 74 24 08          	divl   0x8(%esp)
f010693f:	89 d6                	mov    %edx,%esi
f0106941:	89 c3                	mov    %eax,%ebx
f0106943:	f7 64 24 0c          	mull   0xc(%esp)
f0106947:	39 d6                	cmp    %edx,%esi
f0106949:	72 0c                	jb     f0106957 <__udivdi3+0xb7>
f010694b:	89 f9                	mov    %edi,%ecx
f010694d:	d3 e5                	shl    %cl,%ebp
f010694f:	39 c5                	cmp    %eax,%ebp
f0106951:	73 5d                	jae    f01069b0 <__udivdi3+0x110>
f0106953:	39 d6                	cmp    %edx,%esi
f0106955:	75 59                	jne    f01069b0 <__udivdi3+0x110>
f0106957:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010695a:	31 ff                	xor    %edi,%edi
f010695c:	89 fa                	mov    %edi,%edx
f010695e:	83 c4 1c             	add    $0x1c,%esp
f0106961:	5b                   	pop    %ebx
f0106962:	5e                   	pop    %esi
f0106963:	5f                   	pop    %edi
f0106964:	5d                   	pop    %ebp
f0106965:	c3                   	ret    
f0106966:	8d 76 00             	lea    0x0(%esi),%esi
f0106969:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0106970:	31 ff                	xor    %edi,%edi
f0106972:	31 c0                	xor    %eax,%eax
f0106974:	89 fa                	mov    %edi,%edx
f0106976:	83 c4 1c             	add    $0x1c,%esp
f0106979:	5b                   	pop    %ebx
f010697a:	5e                   	pop    %esi
f010697b:	5f                   	pop    %edi
f010697c:	5d                   	pop    %ebp
f010697d:	c3                   	ret    
f010697e:	66 90                	xchg   %ax,%ax
f0106980:	31 ff                	xor    %edi,%edi
f0106982:	89 e8                	mov    %ebp,%eax
f0106984:	89 f2                	mov    %esi,%edx
f0106986:	f7 f3                	div    %ebx
f0106988:	89 fa                	mov    %edi,%edx
f010698a:	83 c4 1c             	add    $0x1c,%esp
f010698d:	5b                   	pop    %ebx
f010698e:	5e                   	pop    %esi
f010698f:	5f                   	pop    %edi
f0106990:	5d                   	pop    %ebp
f0106991:	c3                   	ret    
f0106992:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106998:	39 f2                	cmp    %esi,%edx
f010699a:	72 06                	jb     f01069a2 <__udivdi3+0x102>
f010699c:	31 c0                	xor    %eax,%eax
f010699e:	39 eb                	cmp    %ebp,%ebx
f01069a0:	77 d2                	ja     f0106974 <__udivdi3+0xd4>
f01069a2:	b8 01 00 00 00       	mov    $0x1,%eax
f01069a7:	eb cb                	jmp    f0106974 <__udivdi3+0xd4>
f01069a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01069b0:	89 d8                	mov    %ebx,%eax
f01069b2:	31 ff                	xor    %edi,%edi
f01069b4:	eb be                	jmp    f0106974 <__udivdi3+0xd4>
f01069b6:	66 90                	xchg   %ax,%ax
f01069b8:	66 90                	xchg   %ax,%ax
f01069ba:	66 90                	xchg   %ax,%ax
f01069bc:	66 90                	xchg   %ax,%ax
f01069be:	66 90                	xchg   %ax,%ax

f01069c0 <__umoddi3>:
f01069c0:	55                   	push   %ebp
f01069c1:	57                   	push   %edi
f01069c2:	56                   	push   %esi
f01069c3:	53                   	push   %ebx
f01069c4:	83 ec 1c             	sub    $0x1c,%esp
f01069c7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01069cb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01069cf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01069d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01069d7:	85 ed                	test   %ebp,%ebp
f01069d9:	89 f0                	mov    %esi,%eax
f01069db:	89 da                	mov    %ebx,%edx
f01069dd:	75 19                	jne    f01069f8 <__umoddi3+0x38>
f01069df:	39 df                	cmp    %ebx,%edi
f01069e1:	0f 86 b1 00 00 00    	jbe    f0106a98 <__umoddi3+0xd8>
f01069e7:	f7 f7                	div    %edi
f01069e9:	89 d0                	mov    %edx,%eax
f01069eb:	31 d2                	xor    %edx,%edx
f01069ed:	83 c4 1c             	add    $0x1c,%esp
f01069f0:	5b                   	pop    %ebx
f01069f1:	5e                   	pop    %esi
f01069f2:	5f                   	pop    %edi
f01069f3:	5d                   	pop    %ebp
f01069f4:	c3                   	ret    
f01069f5:	8d 76 00             	lea    0x0(%esi),%esi
f01069f8:	39 dd                	cmp    %ebx,%ebp
f01069fa:	77 f1                	ja     f01069ed <__umoddi3+0x2d>
f01069fc:	0f bd cd             	bsr    %ebp,%ecx
f01069ff:	83 f1 1f             	xor    $0x1f,%ecx
f0106a02:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0106a06:	0f 84 b4 00 00 00    	je     f0106ac0 <__umoddi3+0x100>
f0106a0c:	b8 20 00 00 00       	mov    $0x20,%eax
f0106a11:	89 c2                	mov    %eax,%edx
f0106a13:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106a17:	29 c2                	sub    %eax,%edx
f0106a19:	89 c1                	mov    %eax,%ecx
f0106a1b:	89 f8                	mov    %edi,%eax
f0106a1d:	d3 e5                	shl    %cl,%ebp
f0106a1f:	89 d1                	mov    %edx,%ecx
f0106a21:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0106a25:	d3 e8                	shr    %cl,%eax
f0106a27:	09 c5                	or     %eax,%ebp
f0106a29:	8b 44 24 04          	mov    0x4(%esp),%eax
f0106a2d:	89 c1                	mov    %eax,%ecx
f0106a2f:	d3 e7                	shl    %cl,%edi
f0106a31:	89 d1                	mov    %edx,%ecx
f0106a33:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0106a37:	89 df                	mov    %ebx,%edi
f0106a39:	d3 ef                	shr    %cl,%edi
f0106a3b:	89 c1                	mov    %eax,%ecx
f0106a3d:	89 f0                	mov    %esi,%eax
f0106a3f:	d3 e3                	shl    %cl,%ebx
f0106a41:	89 d1                	mov    %edx,%ecx
f0106a43:	89 fa                	mov    %edi,%edx
f0106a45:	d3 e8                	shr    %cl,%eax
f0106a47:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0106a4c:	09 d8                	or     %ebx,%eax
f0106a4e:	f7 f5                	div    %ebp
f0106a50:	d3 e6                	shl    %cl,%esi
f0106a52:	89 d1                	mov    %edx,%ecx
f0106a54:	f7 64 24 08          	mull   0x8(%esp)
f0106a58:	39 d1                	cmp    %edx,%ecx
f0106a5a:	89 c3                	mov    %eax,%ebx
f0106a5c:	89 d7                	mov    %edx,%edi
f0106a5e:	72 06                	jb     f0106a66 <__umoddi3+0xa6>
f0106a60:	75 0e                	jne    f0106a70 <__umoddi3+0xb0>
f0106a62:	39 c6                	cmp    %eax,%esi
f0106a64:	73 0a                	jae    f0106a70 <__umoddi3+0xb0>
f0106a66:	2b 44 24 08          	sub    0x8(%esp),%eax
f0106a6a:	19 ea                	sbb    %ebp,%edx
f0106a6c:	89 d7                	mov    %edx,%edi
f0106a6e:	89 c3                	mov    %eax,%ebx
f0106a70:	89 ca                	mov    %ecx,%edx
f0106a72:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0106a77:	29 de                	sub    %ebx,%esi
f0106a79:	19 fa                	sbb    %edi,%edx
f0106a7b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0106a7f:	89 d0                	mov    %edx,%eax
f0106a81:	d3 e0                	shl    %cl,%eax
f0106a83:	89 d9                	mov    %ebx,%ecx
f0106a85:	d3 ee                	shr    %cl,%esi
f0106a87:	d3 ea                	shr    %cl,%edx
f0106a89:	09 f0                	or     %esi,%eax
f0106a8b:	83 c4 1c             	add    $0x1c,%esp
f0106a8e:	5b                   	pop    %ebx
f0106a8f:	5e                   	pop    %esi
f0106a90:	5f                   	pop    %edi
f0106a91:	5d                   	pop    %ebp
f0106a92:	c3                   	ret    
f0106a93:	90                   	nop
f0106a94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106a98:	85 ff                	test   %edi,%edi
f0106a9a:	89 f9                	mov    %edi,%ecx
f0106a9c:	75 0b                	jne    f0106aa9 <__umoddi3+0xe9>
f0106a9e:	b8 01 00 00 00       	mov    $0x1,%eax
f0106aa3:	31 d2                	xor    %edx,%edx
f0106aa5:	f7 f7                	div    %edi
f0106aa7:	89 c1                	mov    %eax,%ecx
f0106aa9:	89 d8                	mov    %ebx,%eax
f0106aab:	31 d2                	xor    %edx,%edx
f0106aad:	f7 f1                	div    %ecx
f0106aaf:	89 f0                	mov    %esi,%eax
f0106ab1:	f7 f1                	div    %ecx
f0106ab3:	e9 31 ff ff ff       	jmp    f01069e9 <__umoddi3+0x29>
f0106ab8:	90                   	nop
f0106ab9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106ac0:	39 dd                	cmp    %ebx,%ebp
f0106ac2:	72 08                	jb     f0106acc <__umoddi3+0x10c>
f0106ac4:	39 f7                	cmp    %esi,%edi
f0106ac6:	0f 87 21 ff ff ff    	ja     f01069ed <__umoddi3+0x2d>
f0106acc:	89 da                	mov    %ebx,%edx
f0106ace:	89 f0                	mov    %esi,%eax
f0106ad0:	29 f8                	sub    %edi,%eax
f0106ad2:	19 ea                	sbb    %ebp,%edx
f0106ad4:	e9 14 ff ff ff       	jmp    f01069ed <__umoddi3+0x2d>
