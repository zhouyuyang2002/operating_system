Structure:

1. Page Table: 0x100000 to ?, $npages$ number of PageInfos,
PageInfo{
  pp_link -> Link to the next unappied free pages, NULL if applied
  pp_ref  -> number of references to the page,     non-zero if applied
}


Page Dict(Lv1): 1, (4 byte each)
4096 Byte(PGSIZE) contains 1024 pde_t, a pointer to Page Table
Page Table(Lv2): Maximize 1024, (4 byte each)
4096 Byte(PGSIZE) contains 1024 pte_t, a pointer to a Page
PageInfo       : Maximize 1024^2, (4+4 byte each), Initally Malloced


First: Malloc 1 Page for page_table's info
Second: Malloc, several pages, for page management


Question 1: uintptr_t(Because T* is uintptr_t)
Question 2: 
(961~1024) 0xf00~0xfff top 64 Tables is mapped to Physics Memory in 0x000~0x0ff
960        0xefc~0xeff KERNBASE

Question 3: The PageTable & PageDict, each of them(pde_t,pte_t) have 12 bit of memory
represents the access for each user, include kernel and user.
When User try to read/write some piece of memory, the kernel will first check that whether
the user have the access to read/write the page. If Yes, then the user can resd/write the piece.
For the PageTable which contains the kernel memory and kernel's code,  Initally we have already set it
unreadable/unwriteable to user, so if the user try to visit it, it will report  error before edit it

Question 4: 1 PageDict, 2^10 Page Table, 2^20 Page, 2^32 Byte of Memory

Question 5: 8Mib for PageInfo, 4Mib for PageTable, 4Kib for PageDict

Question 6: kern/entry.S, Line 67~69
Initally, Virtual Address [0,4Mib] is Mapped to [0,4Mib], so running in a low EIP is ok.
But after pg_dir is set up, It's abandoned to use [0,4Mib] any forther..
