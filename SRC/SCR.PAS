{
 MIT License

Copyright (c) 2020 Viacheslav Komenda

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
}
{$G-,S-,R-,I-}
unit scr;

interface

var screen:array[0..160*50*2] of char;
var cursor_start, cursor_end : byte;

procedure init;
procedure cls(clr:byte);
procedure cln(x,y:integer;clr:byte);
procedure print(x, y:integer; clr:byte; s:string);
procedure printhl(x, y:integer; clr, hlclr:byte; s:string);
procedure hprint(x,y:integer;clr:byte;c:char;len:integer);
procedure vprint(x,y:integer;clr:byte;c:char;len:integer);
procedure chcolor(x,y:integer;clr:byte;len:integer);

procedure push_buf;
procedure pop_buf;
procedure pick_buf;
procedure show;

procedure locate(x, y:integer);

procedure cursor_off;
function get_cursor_start:byte;
function get_cursor_end:byte;
procedure set_cursor(start_line, end_line : byte);

procedure set_blink(on : boolean);

procedure push;
procedure pop;

function getwidth:integer;
function getheight:integer;

function getx:integer;
function gety:integer;

implementation

const vseg : word = 0;

type

PScr=^TScr;
TScr=record
        prev   : PScr;
        size   : word;
        x, y   : integer;
        buf    : byte;
end;

const

last_scr        : PScr = nil;
last_scr_buf    : PScr = nil;

function getheight:integer;
begin
        getheight := mem[$000:$484] + 1;
end;

function getwidth:integer;
begin
        getwidth := memw[$000:$44a];
end;

procedure cls(clr:byte);assembler;
asm
        call       getwidth
        push       ax
        call       getheight
        pop        cx
        mul        cx
        mov        cx, ax
        mov        ah, clr
        mov        al, ' '
        push       ds
        pop        es
        lea        di,screen
        cld
        repz       stosw
end;

procedure cln(x,y:integer;clr:byte);assembler;
asm
        call       getwidth
        push       ax
        mov        cx, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        pop        cx
        sub        cx, x
        mov        ah, clr
        mov        al, ' '
        cld
        push       es
        push       ds
        pop        es
        repz       stosw
        pop        es
end;

procedure hprint(x,y:integer;clr:byte;c:char;len:integer);assembler;
asm
        call       getwidth
        mov        cx, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        mov        cx, len
        mov        ah, clr
        mov        al, c
        cld
        push       es
        push       ds
        pop        es
        repz       stosw
        pop        es
end;

procedure chcolor(x,y:integer;clr:byte;len:integer);assembler;
asm
        call       getwidth
        mov        cx, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        inc        di
        mov        cx, len
        mov        al, clr
        cld
        push       es
        push       ds
        pop        es
        or         cx, cx
        jz         @end
@cont:
        stosb
        inc        di
        dec        cx
        jnz        @cont
@end:
        pop        es
end;

procedure vprint(x,y:integer;clr:byte;c:char;len:integer);assembler;
asm
        call       getwidth
        mov        bx, ax
        shl        ax, 1
        xchg       bx, ax
        mov        cx, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        mov        cx, len
        mov        ah, clr
        mov        al, c
        push       es
        push       ds
        pop        es
        or         cx, cx
        jz         @end
@cont:
        mov        es:[di], ax
        add        di, bx
        dec        cx
        jnz        @cont
@end:
        pop        es
end;

procedure print(x, y:integer; clr:byte; s:string);assembler;
asm
        push       es
        push       ds
        call       getwidth
        xor        ah, ah
        mov        cx, ax
        mov        ax, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        push       ds
        pop        es
        lea        bx, s
        mov        si, ss:[bx]
        mov        ax, ss:[bx+2]
        mov        ds, ax
        xor        ah, ah
        lodsb
        mov        cx, ax
        or         ax, ax
        jz         @end
        mov        ah, ss:clr
        cld
@cont:
        lodsb
        stosw
        dec        cx
        jnz        @cont
@end:
        pop        ds
        pop        es
end;

procedure printhl(x, y:integer; clr, hlclr:byte; s:string);assembler;
asm
        push       es
        push       ds
        call       getwidth
        xor        ah, ah
        mov        cx, ax
        mov        ax, y
        mul        cx
        add        ax, x
        shl        ax, 1
        lea        di, screen
        add        di, ax
        push       ds
        pop        es
        lea        bx, s
        mov        si, ss:[bx]
        mov        ax, ss:[bx+2]
        mov        ds, ax
        xor        ah, ah
        lodsb
        mov        cx, ax
        or         ax, ax
        jz         @end
        mov        ah, ss:clr
        mov        bh, ss:hlclr
        cld
@cont:
        lodsb
        cmp        al, '~'
        jnz        @print
        xchg       ah,bh
        jmp        @cont2
@print:
        stosw
@cont2:
        dec        cx
        jnz        @cont
@end:
        pop        ds
        pop        es
end;

procedure show;assembler;
asm
        call       getwidth
        push       ax
        call       getheight
        pop        cx
        mul        cx
        mov        cx, ax
        lea        si, screen
        xor        di, di
        push       es
        mov        bx, vseg
        mov        es, bx
        cld
        repz       movsw
        pop        es
end;

procedure push;
var s : word;
        p : PScr;
begin
        s := (getwidth * getheight) shl 1;
        getmem(p, s + sizeof(TScr) - 1);
        p^.size := s;
        p^.prev := last_scr;
        p^.x := getx;
        p^.y := gety;
        move(mem[vseg:0], p^.buf, p^.size);
        last_scr := p;
end;

procedure pop;
var p : PScr;
begin
        if last_scr = nil then exit;
        move(last_scr^.buf, mem[vseg:0], last_scr^.size);
        p := last_scr;
        last_scr := last_scr^.prev;
        scr.locate(p^.x, p^.y);
        freemem(p, p^.size + sizeof(TScr) - 1);
end;

procedure locate(x, y:integer);assembler;
asm
        push       ds
        xor        ax, ax
        mov        ds, ax
        mov        bh, byte ptr [$462]
        pop        ds
        mov        dl, byte ptr [x]
        mov        dh, byte ptr [y]
        mov        ah, 2
        int        $10
end;

function getx:integer;
begin

        getx := mem[0:(mem[0:$462] shl 1) + $450] and $ff;
end;

function gety:integer;
begin
        gety := mem[0:(mem[0:$462] shl 1) + $451] and $ff;
end;

procedure push_buf;
var s : word;
        p : PScr;
begin
        s := (getwidth * getheight) shl 1;
        getmem(p, s + sizeof(TScr) - 1);
        p^.size := s;
        p^.prev := last_scr_buf;
        p^.x := getx;
        p^.y := gety;
        move(screen, p^.buf, p^.size);
        last_scr_buf := p;
end;

procedure pop_buf;
var p : PScr;
begin
        if last_scr_buf = nil then exit;
        move(last_scr_buf^.buf, screen, last_scr_buf^.size);
        p := last_scr_buf;
        last_scr_buf := last_scr_buf^.prev;
        scr.locate(p^.x, p^.y);
        freemem(p, p^.size + sizeof(TScr) - 1);
end;

procedure pick_buf;
begin
        if last_scr_buf = nil then exit;
        move(last_scr_buf^.buf, screen, last_scr_buf^.size);
        scr.locate(last_scr_buf^.x, last_scr_buf^.y);
end;

procedure set_cursor(start_line, end_line : byte);assembler;
asm
        push       ds
        push       es
        push       bp
        mov        ch, byte ptr [start_line]
        mov        cl, byte ptr [end_line]
        mov        ah, 1
        int        $10
        pop        bp
        pop        es
        pop        ds
end;

procedure cursor_off;
begin
        set_cursor($20, $20);
end;

procedure set_blink(on : boolean);assembler;
asm
        mov        bl, byte ptr on
        mov        ax, $1003
        int        $10
end;

function get_cursor_start:byte;assembler;
asm
                mov        ah,3
                int        $10
                mov        al, ch
end;

function get_cursor_end:byte;assembler;
asm
                mov        ah,3
                int        $10
                mov        al, cl
end;


procedure init;
begin
        vseg := segb800;
        set_blink(false);
        cursor_start := get_cursor_start;
        cursor_end := get_cursor_end;
end;

begin
        init;
end.