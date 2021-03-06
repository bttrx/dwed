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
unit dwedlnch;

interface

const DEVFILE : string = 'DWED:';

procedure launcher(var exename : string);
function is_installed : boolean;

implementation

uses dos, strutil, sysext, lfn;

Type
PString = ^String;

var
        oldInt21        : pointer;
        requested_cmd   : string[255];
        path            : string;
        temp            : string;
        code            : integer;

procedure cmp_name;assembler;
asm
        pushf
        xchg       bx, dx
        push       bx
        xor        al, al
        cmp        ah, $3D { open }
        je         @cmp_names
        cmp        ah, $3C { create}
        je         @cmp_names
        jmp        @no
@cmp_names:
        cmp        byte ptr[BX], 'D'
        je         @ok1
        cmp        byte ptr[BX], 'd'
        je         @ok1
        jmp        @no
@ok1:
        inc        bx
        cmp        byte ptr[BX], 'W'
        je         @ok2
        cmp        byte ptr[BX], 'w'
        je         @ok2
        jmp        @no
@ok2:
        inc        bx
        cmp        byte ptr[BX], 'E'
        je         @ok3
        cmp        byte ptr[BX], 'e'
        je         @ok3
        jmp        @no
@ok3:
        inc        bx
        cmp        byte ptr[BX], 'D'
        je         @ok4
        cmp        byte ptr[BX], 'd'
        je         @ok4
        jmp        @no
@ok4:
        inc        bx
        cmp        byte ptr[BX], ':'
        jne        @no

        inc        bx
        cmp        byte ptr[BX], 0
        jne        @no

        inc        al
@no:
        pop        bx
        xchg       bx, dx
        popf
end;

procedure write_hook;assembler;
asm
        push       di
        push       si
        push       es
        push       cx
        mov        si, dx
        mov        di, offset requested_cmd
        mov        dx, seg requested_cmd
        mov        es, dx
        xor        ch,ch
        cld
        rep        movsb
        pop        cx
        pop        es
        pop        si
        pop        di
end;

procedure read_hook;assembler;
asm
        push       di
        push       si
        push       es
        push       ds
        push       dx
        push       cx

        push       ds
        pop        es
        mov        di, dx
        mov        si, offset temp
        mov        dx, seg temp
        mov        ds, dx
        xor        ch, ch
        mov        cl, byte ptr [si]
        inc        cx
        push       cx
        cld
        rep        movsb
        pop        ax

        pop        cx
        pop        dx
        pop        ds
        pop        es
        pop        si
        pop        di
end;

procedure newInt21;assembler;
asm
        pushf
        push       ax
        call       cmp_name
        or         al, al
        pop        ax
        jz         @cont3
        popf
        mov        ax, $564B
        jmp        @ret_val
@cont3: cmp        ah, $40 { write file}
        jne        @cont4
        cmp        bx, $564B
        jne        @cont4
        call       write_hook
        popf
        mov        ax, cx
        jmp        @ret_val
@cont4: cmp        ah, $3F { read file }
        jne        @cont5
        cmp        bx, $564B
        jne        @cont5
        call       read_hook
        popf
        mov        ax, cx
        jmp        @ret_val
@cont5:
        cmp        ah, $3e { close file }
        jne        @cont6
        cmp        bx, $564B
        jne        @cont6
        popf
        mov        ax, $0
        jmp        @ret_val
@cont6:
        cmp        ah, $42 { seek file }
        jne        @cont7
        cmp        bx, $564B
        jne        @cont7
        xor        ax, ax
        xor        dx, dx
@cont7:
        popf
        push       ds
        push       ax
        mov        ax, SEG oldInt21
        mov        ds, ax
        mov        ax, word ptr [oldInt21]
        mov        word ptr cs:[@oInt21], ax
        mov        ax, word ptr [oldInt21 + 2]
        mov        word ptr cs:[@oInt21 + 2], ax
        pop        ax
        pop        ds
        jmp        dword ptr cs:[@oInt21]
@oInt21:
        dd         0
@rval:
        dw         0
@ret_val:
        mov        word ptr cs:[@rval], ax
        pop        ax
        mov        word ptr cs:[@oInt21], ax
        pop        ax
        mov        word ptr cs:[@oInt21 + 2], ax
        popf
        clc
        pushf
        mov        ax, word ptr cs:[@oInt21 + 2]
        push       ax
        mov        ax, word ptr cs:[@oInt21]
        push       ax
        mov        ax, word ptr cs:[@rval]
        iret
end;

procedure init;
begin
        getIntVec($21, oldInt21);
        setIntVec($21, @newInt21);
        requested_cmd := '';
end;

procedure done;
begin
        setIntVec($21, oldInt21);
        requested_cmd := trim(requested_cmd);
end;

function is_installed : boolean;
begin
        is_installed := lfn.file_exists(DEVFILE);
end;

function rchar : char;
const chars : string = '0123456789-_qwertyuiopasdfghjklzxcvbnm';
begin
        rchar := chars[1 + random(length(chars))];
end;

function rfname : string;
var i : integer;
    r : string;
begin
        r := '';
        for i := 1 to 8 do r := r + rchar;
        r := r + '.';
        for i := 1 to 3 do r := r + rchar;
        rfname := r;
end;

var     cur_drive : byte;
        cur_dir   : string;

procedure launcher(var exename : string);
var params   : string;
    i        : integer;
begin
        if is_installed then begin
                writeln('DWED cycle execution detected.');
                halt(1);
        end;
        randomize;
        params := trim(PString(ptr(PrefixSeg, $80))^);
        cur_drive := sysext.getCurrentDisk;
        cur_dir := sysext.getCurrentDir;
        path := getpathname(paramstr(0));
        temp := rfname;
        while true do begin
                sysext.setCurrentDisk(cur_drive);
                sysext.setCurrentDir(cur_dir);
                init;
                exec(path + exename, params);
                code := 1;
                if DosError = 0 then code := DosExitCode;
                done;
                if (code = 254) and (length(requested_cmd) <> 0) then begin
                        writeln(requested_cmd);
                        exec(getenv('COMSPEC'), '/C ' + requested_cmd);
                        asm
                                xor        ax, ax
                                int        $16
                        end
                end else break;
        end;
        halt(code);
end;

end.
