.globl _bbCallMethod.text_bbCallMethod:	pushl   %ebp	movl    %esp,%ebp	subl    0x10(%ebp),%esp	pushl  0x10(%ebp)	pushl  0xc(%ebp)	pushl   %esp	calll   _memcpy	addl    $0x4,%esp	calll   *0x8(%ebp)	movl    %ebp,%esp	popl    %ebp	ret