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
{$A-,G-,S-,R-,I-}
unit dwedtype;

interface

uses strs, dwedhl;

const

SCRU_QUIT   = 1;
SCRU_NONE   = 2;
SCRU_TOP    = 3;
SCRU_CLINE  = 4;
SCRU_FULL   = 5;

const

CB_SIZE = 32 * 1024;

type

PColorConfig =^ TColorConfig;
TColorConfig = record
        top           : byte;
        text          : byte;
        text_hl       : byte;
        text_sel      : byte;
        menu          : byte;
        menu_sel      : byte;
        help_menu     : byte;
        help_menu_sel : byte;
        help          : byte;
        help_hl       : byte;
end;

PConfig =^ TConfig;
TConfig = record
        width         : integer;
        height        : integer;
        color         : TColorConfig;
        tab_size      : integer;
end;

TLineEditorContext = record
        x         : integer;
        line      : string;
        chg       : boolean;
        selection : boolean;
        sel_row   : longint;
        sel_x     : integer;
end;

PFileContext =^ TFileContext;
TFileContext = record
        fname        : string;
        sfname       : string;
        st           : SourceType;
        chg          : boolean;
        scrofs       : longint;
        total        : longint;
        scrx, scry   : integer;
        next         : PFileContext;
        rline        : EditorStr;
        cline        : EditorStr;
        scrline      : EditorStr;
        editor       : TLineEditorContext;
        config       : PConfig;
end;

PEditorContext =^ TEditorContext;
TEditorContext = record
        ins            : boolean;
        current        : PFileContext;
        all            : PFileContext;
        clipboard      : array[0..CB_SIZE] of char;
        search         : string[64];
        searchCaseSens : boolean;
        replace        : string[64];
        config         : TConfig;
        help_topic_id  : integer;
end;

PEvent =^ TEvent;
TEvent = record
        key            : word;
        is_ctrl        : boolean;
        is_shift       : boolean;
        is_alt         : boolean;
end;

TEventProc = function(var ctx : TEditorContext; e : PEvent) : integer;
PEventProc =^ TEventProc;

PEventHandler =^ TEventHandler;
TEventHandler = record
        event           : TEvent;
        reset_selection : boolean;
        proc            : TEventProc;
        next            : PEventHandler;
end;

implementation

end.