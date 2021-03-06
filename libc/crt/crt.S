/*-*- mode:unix-assembly; indent-tabs-mode:t; tab-width:8; coding:utf-8     -*-│
│vi: set et ft=asm ts=8 tw=8 fenc=utf-8                                     :vi│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2020 Justine Alexandra Roberts Tunney                              │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/
#include "libc/dce.h"
#include "libc/macros.h"
#include "libc/notice.inc"
#include "libc/runtime/internal.h"
.section .start,"ax",@progbits
.align	16

//	System Five userspace program entrypoint.
//
//	@param	rsp is [n,argv₀..argvₙ₋₁,0,envp₀..,0,auxv₀..,0,..]
//	@note	FreeBSD is special (see freebsd/lib/csu/amd64/...)
//	@noreturn
_start:
#if SupportsFreebsd()
	test	%rdi,%rdi
	cmovnz	%rdi,%rsp
	jz	0f
	movb	$FREEBSD,__hostos(%rip)
#endif
0:	mov	(%rsp),%ebx			# argc
	lea	8(%rsp),%rsi			# argv
	lea	24(%rsp,%rbx,8),%rdx		# envp
	.frame0
//	bofram	9f
	.weak	ape_idata_iat
	.weak	ape_idata_iatend
	ezlea	missingno,ax			# make win32 imps noop
	ezlea	ape_idata_iat,di
	ezlea	ape_idata_iatend,cx
	sub	%rdi,%rcx
	shr	$3,%ecx
	rep stosq
	xor	%eax,%eax			# find end of environ
	or	$-1,%ecx
	mov	%rdx,%rdi
	repnz scasq
	mov	%rdi,%rcx			# auxv
#if SupportsXnu()
	testb	IsXnu()
	jz	1f				# polyfill xnu auxv
	push	$0				# auxv[1][1]=0
	push	$0				# auxv[1][0]=0
	mov	(%rcx),%rax			# executable_path=BIN
	lea	16(%rax),%rax			# BIN
	push	%rax				# auxv[0][0]=BIN
	push	$31				# auxv[0][0]=AT_EXECFN
	mov	%rsp,%rcx			# auxv
#endif
1:	mov	%ebx,%edi
	call	cosmo
9:	ud2
	.endfn	_start,weak,hidden

#if SupportsXnu()
//	Macintosh userspace program entrypoint.
//
//	@param	rsp is [n,argv₀..argvₙ₋₁,0,envp₀..,0,auxv₀..,0,..]
//	@note	FreeBSD is special (see freebsd/lib/csu/amd64/...)
//	@noreturn
_xnu:	movb	$XNU,__hostos(%rip)
	jmp	0b
	.endfn	_xnu,weak,hidden
#endif
