# DWED

Text file editor for MS-DOS and 8086 CPU designed in modern style for a IBM XT-grade PC.

Main features:

* Support files over 64k
* Support syntax hightlight (C/C++/C--, Pascal, Basic, Assembler, Xml/Html, text files etc)
* Support multiple file editing at the same time
* Support internal clipboard (size up to 32k)
* Support unix-like text files for open
* Dont require DPMI-server or 80286 CPU

Restrictions:

* This software is writen in Borland Pascal, so string length is limited to 255 chars.
* DOS-conventional memory will be enought to load file up to ~300k..400k (expect - 300k border).
* No Undo/Redo functionality. The reason is the same as why i dont build AST for syntax hightlight - here is no memory for it.

# How to run

	dwed.exe - dos real mode
	dwed16.exe - 16bit DPMI

# Screenshots

### Text file hightlight
![Image Screenshot - Txt syntax hightlighjt](https://github.com/DosWorld/dwed/raw/main/DWED-TXT.PNG)

### Turbo Pascal syntax hightlight
![Image Screenshot - Pascal syntax hightlighjt](https://github.com/DosWorld/dwed/raw/main/DWED-PAS.PNG)

### Power Basic syntax hightlight
![Image Screenshot - Basic syntax hightlighjt](https://github.com/DosWorld/dwed/raw/main/DWED-BAS.PNG)

### C syntax hightlight
![Image Screenshot - C syntax hightlighjt](https://github.com/DosWorld/dwed/raw/main/DWED-C.PNG)

### Help mode
![Image Screenshot - C syntax hightlighjt](https://github.com/DosWorld/dwed/raw/main/DWED-HLP.PNG)

### ASCII Table addon
![Image ASCII Table addon](https://github.com/DosWorld/dwed/raw/main/DWED-ASC.PNG)

# Build

To build binaries, you need Borland Pascal 7.0 in path and my small make. Then - type

      make

# LICENSE

MIT License
