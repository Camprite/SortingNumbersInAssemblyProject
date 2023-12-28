;Aplikacja korzystaj¹ca z otwartego okna konsoli
;Aplikacja maj¹ca na celu zapisywanie liczb do pliku, odczytywanie odraz sortowanie
;Przyjêty algorytm sortowania: Bubble sort

.386
.MODEL flat, STDCALL
OPTION LJMP ;Obs³uga d³u¿szych skoków

;--- stale ---
STD_INPUT_HANDLE                     equ -10
STD_OUTPUT_HANDLE                    equ -11
GENERIC_READ                         equ 80000000h
GENERIC_WRITE                        equ 40000000h
CREATE_NEW                           equ 1
CREATE_ALWAYS                        equ 2
OPEN_EXISTING                        equ 3
OPEN_ALWAYS                          equ 4
FILE_BEGIN							 equ 0h ;MoveMethod dla SetFilePointe
FILE_CURRENT                         equ 1h ;MoveMethod dla SetFilePointe
FILE_END                             equ 2h ;MoveMethod dla SetFilePointe
;--- prototypy ---
CharToOemA PROTO :DWORD,:DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
CreateFileA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD 
GetCurrentDirectoryA PROTO :DWORD,:DWORD  
SetFilePointer PROTO :DWORD,:DWORD,:DWORD,:DWORD  
ExitProcess PROTO :DWORD
wsprintfA PROTO C :VARARG
lstrlenA PROTO :DWORD
lstrcpyA PROTO :DWORD,:DWORD  
lstrcatA PROTO :DWORD,:DWORD  
CloseHandle PROTO :DWORD  
WriteFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD  
ReadFile PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ScanInt PROTO 
nseed PROTO :DWORD
nrandom PROTO :DWORD
GetTickCount PROTO
dwtoa PROTO :DWORD, :DWORD 
;------------------------------------------
;-------------
_DATA SEGMENT
	adresBufora	DD	?
	hout	DD	?
	hinp	DD	?
	rangeFrom DD ?
	rangeTo DD ?
	range DD ?
	randomNumber DD ?
	liczba1 DD ?
	liczba2 DD ?
	distance DD 0
	distanceMin DD 0
	distancePierwsza DD 0
	distanceDruga DD 0
	min DD ?
	numbersAmount DD ?
	openedFileHandle DD ?
	tempFileHandle DD ?
	scanedChars DD ?
	scanedCharsMin DD ?
	inputCharsReaded DD ?
	bytesWritten DD ?
	bytesToWrite DB ?
	separator DD 3Bh
	odwiedzone DD 127
	buforPierwszy	DB	8 dup(?)
	buforDrugi	DB	8 dup(?)

	naglow	DB	"Autor aplikacji  Dawid Borkowski.",0,0Ah
	ALIGN	4	; przesuniecie do adresu podzielnego na 4
	rozmN	DD	$ - naglow	;liczba znaków w tablicy

	tempFile	DB	"temporary.txt",0,0
	ALIGN	4	; przesuniecie do adresu podzielnego na 4
	rozmTempFile	DD	$ - tempFile	;liczba znaków w tablicy


	getFilenameMsg DB 0Dh,0Ah,"Podaj nazwe pliku: ",0
	ALIGN	4
	sizeFilenameMsg	DD	$ - getFilenameMsg ;liczba znaków w tablicy

	;	---		Opcje menu		---
	menuMsg1 DB 0Dh,0Ah,"Wybierz opcje: ",0
	ALIGN	4
	sizeMsg1	DD	$ - menuMsg1 ;liczba znaków w tablicy

	menuMsg2 DB 0Dh,0Ah,"1. Losuj liczby i wpisz do pliku. ",0
	ALIGN	4
	sizeMsg2	DD	$ - menuMsg2 ;liczba znaków w tablicy
	
	menuMsg3 DB 0Dh,0Ah,"2. Sortuj liczby.",0
	ALIGN	4
	sizeMsg3	DD	$ - menuMsg3 ;liczba znaków w tablicy
	
	menuMsg4 DB 0Dh,0Ah,"3. Wypisz liczby z pliku. ",0
	ALIGN	4
	sizeMsg4	DD	$ - menuMsg4 ;liczba znaków w tablicy	

	menuMsg5 DB 0Dh,0Ah,"4. Zakoñcz program. ",0,0Ah
	ALIGN	4
	sizeMsg5	DD	$ - menuMsg5 ;liczba znaków w tablicy

	menuInvalidArgument DB 0Dh,0Ah,"Nie rozpoznano argumentu, spróbuj ponownie.",0,0Ah
	ALIGN	4
	sizeMenuInvalidArgument	DD	$ - menuInvalidArgument ;liczba znaków w tablicy
	
	rangeMsg1 DB 0Dh,0Ah,"Podaj zakres od: ",0,0Ah
	ALIGN	4
	sizeRangeMsg1 DD	$ - rangeMsg1 ;liczba znaków w tablicy

	rangeMsg2 DB 0Dh,0Ah,"Podaj zakres do: ",0,0Ah
	ALIGN	4
	sizeRangeMsg2 DD	$ - rangeMsg2 ;liczba znaków w tablicy
	

	rangeMsg3 DB 0Dh,0Ah,"Podaj ile liczb ma zostaæ wylosowanych oraz zapisanych: ",0,0Ah
	ALIGN	4
	sizeRangeMsg3 DD	$ - rangeMsg3 ;liczba znaków w tablicy


	menuOption	DB	3 dup(?)
	ALIGN	4
	sizeMenuOption	DD	$ - menuOption

	filenamePathBufor	DB	128 dup(0)
	ALIGN	4
	sizeFilenamePathBufor	DD	$ - filenamePathBufor 

	filenameBufor	DB	128 dup(0)
	ALIGN	4
	sizeFilenameBufor	DD	$ - filenameBufor 
	
	directoryNameBufor	DB	256 dup(0)
	ALIGN	4
	sizeDirectoryNameBufor	DD	$ - directoryNameBufor 	

	tempFileNameBufor	DB	256 dup(0)
	ALIGN	4
	sizeTempFileNameBufor	DD	$ - tempFileNameBufor 
		
	inputBufor	DB	10 dup(?)
	ALIGN	4
	sizeInputBufor DD	$ - inputBufor 


	;---------stare;---------
	rout	DD	0 ;faktyczna liczba wyprowadzonych znaków
	rinp	DD	0 ;faktyczna liczba wprowadzonych znaków
	bufor	DB	128 dup(?)
	rbuf	DD	128
_DATA ENDS
;------------
_TEXT SEGMENT

ReturnDescryptor MACRO handleConstantIn:REQ, handleOut:REQ
 push	handleConstantIn
 call	GetStdHandle
 mov	handleOut,EAX ;; deskryptor bufora konsoli
ENDM

charToOemMACRO MACRO offset1:REQ
	push OFFSET offset1
	push OFFSET offset1
	call CharToOemA
ENDM

getFilenameMACRO MACRO FilenameBufor:REQ, sizeFilenameBufor:REQ
    invoke 	WriteConsoleA, hout, OFFSET getFilenameMsg, sizeFilenameMsg,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET filenameBufor, sizeFilenameBufor, OFFSET rinp,0	; wywo³anie funkcji ReadConsoleA
	mov EAX, rinp
	DEC EAX
	MOV BYTE PTR[filenameBufor+EAX],0
	DEC EAX
	MOV BYTE PTR[filenameBufor+EAX],0
	
ENDM

getGetCurrentDirectoryMACRO MACRO directoryNameBufor:REQ, sizeDirectoryNameBufor:REQ
	invoke GetCurrentDirectoryA,  sizeDirectoryNameBufor, OFFSET directoryNameBufor
	;---------  Dodanie ukoœnika na koniec (5C znak ukoœnika w hexie)
	invoke lstrlenA, OFFSET directoryNameBufor
	MOV BYTE PTR[OFFSET directoryNameBufor + EAX],5Ch
ENDM

getFilenamePathMACRO MACRO directoryNameBufor:REQ, filenameBufor:REQ, filenamePathBufor:REQ, sizeFilenameBuforREQ, sizeDirectoryNameBufor:REQ
	;Makro pobieraj¹ce nazwe pliku do wczytania
	getFilenameMACRO	filenameBufor, sizeFilenameBufor 
	
	;Makro pobieraj¹ce nazwe bierz¹cego katalogu
	getGetCurrentDirectoryMACRO		directoryNameBufor, sizeDirectoryNameBufor 
	
	;Kopiowanie do bufora docelowego scie¿ki katalogu
	invoke lstrcpyA, OFFSET filenamePathBufor, OFFSET directoryNameBufor
	invoke lstrlenA, OFFSET directoryNameBufor
	
	;Konkatenacja z nazw¹ pliku do otworzenia
	invoke lstrcatA, OFFSET filenamePathBufor , OFFSET filenameBufor

ENDM

	getTempFileMACRO MACRO
	;Makro pobieraj¹ce nazwe bierz¹cego katalogu
	getGetCurrentDirectoryMACRO		directoryNameBufor, sizeDirectoryNameBufor 
	
	;Kopiowanie do bufora docelowego scie¿ki katalogu
	invoke lstrcpyA, OFFSET tempFileNameBufor, OFFSET directoryNameBufor
	
	;Konkatenacja z nazw¹ pliku do otworzenia
	invoke lstrcatA, OFFSET tempFileNameBufor , OFFSET tempFile

ENDM

getFileInputHandlerMACRO MACRO filenamePathBufor:REQ, openedFileHandle:REQ

	;Pobanie uchwytu do pliku
	invoke CreateFileA, OFFSET filenamePathBufor, GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	MOV openedFileHandle, EAX
ENDM
;wyrzuc niepotrzebne otwierania
getFileInputHandlerReadMACRO MACRO filenamePathBufor:REQ, openedFileHandle:REQ

	;Pobanie uchwytu do pliku
	invoke CreateFileA, OFFSET filenamePathBufor, GENERIC_READ OR GENERIC_WRITE,0,0,OPEN_EXISTING,0,0
	;TO DO SPRAWDZANIE CZY PLIK SIE POPRAWNIE OTWORZYL
	MOV openedFileHandle, EAX
ENDM

printFileMACRO MACRO
		;Wczytanie nazwy pliku
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor

	;Otwarcie pliku
	getFileInputHandlerReadMACRO filenamePathBufor, openedFileHandle

	MOV EBX, OFFSET inputBufor
	MOV bytesToWrite, 1
	wczytaj:
	invoke ReadFile, openedFileHandle, EBX , 1, OFFSET  inputCharsReaded, 0
	.IF BYTE PTR [EBX] == 59
		MOV EBX, OFFSET inputBufor
		DEC EBX
		dec bytesToWrite
		invoke 	WriteConsoleA, hout, OFFSET inputBufor,bytesToWrite,OFFSET rout,0
		invoke WriteConsoleA, hout, OFFSET separator, 1,OFFSET bytesWritten,0
		MOV bytesToWrite, 0
		MOV EAX, 1
	.ENDIF

	INC ECX
	INC bytesToWrite
	INC EBX
	
	.IF inputCharsReaded == 0
		MOV ECX, 0
	.ENDIF
	
	.IF ECX > 0
		DEC ECX
		JMP wczytaj
	.ENDIF
ENDM

getNumberRangeMACRO MACRO

	;Pobranie wartoœci od
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg1,sizeRangeMsg1,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV rangeFrom, EAX

	;Pobranie wartoœci do
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg2,sizeRangeMsg2,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV rangeTo, EAX

	;Pobranie wartoœci ile
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg3,sizeRangeMsg3,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV numbersAmount, EAX
ENDM

saveRandomNumbersInFile MACRO
invoke GetTickCount ;zwraca w czas w milisekundach od ostatniego uruchomienia systemu
	invoke nseed,EAX; ustawienie wartoœci inicuj¹cej generator liczb pseudolosowych
	
	MOV EAX, rangeTo
	SUB EAX, rangeFrom
	MOV range, EAX

	MOV ECX, numbersAmount

	saveNumber:
	
	invoke nrandom,range ;zwraca w eax liczbê z zakresu 0-zakres
	ADD EAX, rangefrom ;Dodanie przesuniecia od zera
	MOV randomNumber,EAX

	invoke dwtoa,randomNumber, OFFSET  bufor

	invoke lstrlenA, OFFSET  bufor;
	 
	invoke WriteFile, openedFileHandle, OFFSET bufor, EAX, bytesWritten,0
	invoke WriteFile, openedFileHandle, OFFSET separator, 1, bytesWritten,0

	DEC numbersAmount
	MOV ECX, numbersAmount
	loop saveNumber
	
;save macro to delete end



	invoke CloseHandle, openedFileHandle
ENDM

main proc
;--- pobranie uchwytów do wyj i wej
	ReturnDescryptor STD_OUTPUT_HANDLE, hout ;przyk³ad u¿ycia makra
	ReturnDescryptor STD_INPUT_HANDLE, hinp ;przyk³ad u¿ycia tego samego makra z innymi parametrami


;--------- konwersja znaków wiadomoœci na polskie znaki ---------
charToOemMACRO naglow 
charToOemMACRO getFilenameMsg 
charToOemMACRO menuMsg1
charToOemMACRO menuMsg2
charToOemMACRO menuMsg3
charToOemMACRO menuMsg4
charToOemMACRO menuMsg5
charToOemMACRO menuInvalidArgument
charToOemMACRO rangeMsg1
charToOemMACRO rangeMsg2
charToOemMACRO rangeMsg3
;------ wyœwietlenie autora ---------
    invoke 	WriteConsoleA, hout, OFFSET naglow,rozmN,OFFSET rout,0 

;------ pêtla menu ---------
menuLoop:

	;Wypisanie na konsole treœci z bufora menuMsg
	MOV menuOption, 0
    invoke 	WriteConsoleA, hout, OFFSET menuMsg1,sizeMsg1,OFFSET rout,0
	invoke 	WriteConsoleA, hout, OFFSET menuMsg2,sizeMsg2,OFFSET rout,0 
    invoke 	WriteConsoleA, hout, OFFSET menuMsg3,sizeMsg3,OFFSET rout,0 
    invoke 	WriteConsoleA, hout, OFFSET menuMsg4,sizeMsg4,OFFSET rout,0 
    invoke 	WriteConsoleA, hout, OFFSET menuMsg5,sizeMsg5,OFFSET rout,0 
	
	;Pobranie argumentu od uzytkownika
	invoke ReadConsoleA, hinp, OFFSET menuOption, sizeMenuOption, OFFSET rinp, 0
	SUB menuOption, 30h
	.IF menuOption == 1
		JMP losujLiczby
	.ELSEIF menuOption == 2
		JMP sortujLiczby
	.ELSEIF menuOption == 3
		JMP wypiszPlik
	.ELSEIF menuOption == 4
		invoke ExitProcess, 0
	.ELSE
		;Powiadomienie o nierozpoznaniu argumentu
	    invoke 	WriteConsoleA, hout, OFFSET menuInvalidArgument,sizeMenuInvalidArgument,OFFSET rout,0 
		JMP menuLoop
	.ENDIF

	;--------------------------------------------WYPISYWANIE CASE--------------------------------------------
	wypiszPlik:

	;Wypisanie pliku
	printFileMACRO



	
	invoke CloseHandle, openedFileHandle
	JMP menuLoop

	;--------------------------------------------LOSOWANIE CASE--------------------------------------------
	losujLiczby:		

	;Pobranie nazwy pliku
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor
	
	;Pobranie uchwytu do pliku
	getFileInputHandlerMACRO filenamePathBufor, openedFileHandle
	
	;Pobranie zakresu do losowania
	getNumberRangeMACRO
	
	;Losowanie i zapis do pliku
	saveRandomNumbersInFile

	JMP menuLoop

	;--------------------------------------------SORTOWANIE CASE--------------------------------------------
	sortujLiczby:

	getTempFileMACRO
	;Pobanie uchwytu do pliku tymczasowego
	
	invoke CreateFileA, OFFSET tempFileNameBufor, GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	MOV tempFileHandle, EAX

	;Pobranie nazwy pliku
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor
	
	;Pobranie uchwytu do pliku
	getFileInputHandlerReadMACRO filenamePathBufor, openedFileHandle
	


	znajdzNajmniejsza:
		mov distance, 0
		mov min, 99999999
		MOV EBX, OFFSET buforPierwszy
		mov scanedChars, 00
	wczytajZnak:
		
		invoke ReadFile, openedFileHandle, EBX , 1, OFFSET  inputCharsReaded, 0
		INC scanedChars
		INC distance

	
		.IF BYTE PTR [EBX] == 59
			;kasowanie œrednika z bufora
			MOV BYTE PTR [EBX], 00
			MOV EBX, OFFSET buforPierwszy
			DEC EBX
		

			;konwersja bufora na cyfre
			push OFFSET buforPierwszy
			.IF scanedChars > 2
			call ScanInt
			MOV liczba1, EAX
				;zerowanie bufora
				mov ECX,8
				zerowanie:
				MOV BYTE PTR[OFFSET buforPierwszy + ECX],0
				loop zerowanie


			.IF min > EAX
			MOV min, EAX
			MOV EAX, distance
			SUB EAX, scanedChars
			MOV distanceMin, EAX

			MOV EAX, scanedChars
			MOV scanedCharsMin, EAX

			.ENDIF
			.ENDIF
			mov scanedChars, 00
		.ENDIF

		INC EBX
	
		.IF inputCharsReaded == 0
			jmp koniecPliku
			MOV ECX, 0
		.ENDIF
		
		jmp wczytajZnak

	koniecPliku:
	.IF min ==  99999999
		jmp wyjdzStont
	.ENDIF

	invoke SetFilePointer, openedFileHandle, distanceMin, 0, FILE_BEGIN

	invoke ReadFile, openedFileHandle, OFFSET buforPierwszy , scanedCharsMin , OFFSET  inputCharsReaded, 0

	invoke WriteFile, tempFileHandle, OFFSET buforPierwszy, scanedCharsMin , OFFSET bytesWritten,0

	invoke SetFilePointer, openedFileHandle, distanceMin, 0, FILE_BEGIN

	wypelnijSeparatorem:
	invoke WriteFile, openedFileHandle, offset separator, 1,OFFSET bytesWritten,0
	CMP scanedCharsMin, 0
	DEC scanedCharsMin
	JNE wypelnijSeparatorem

	invoke SetFilePointer, openedFileHandle, 0, 0, FILE_BEGIN
	JMP znajdzNajmniejsza

	wyjdzStont:
	invoke CloseHandle, openedFileHandle
	JMP menuLoop




;--- wyœwietlenie wyniku ---------
	invoke	WriteConsoleA, hout, OFFSET bufor, rinp, OFFSET rout, 0; wywo³anie funkcji WriteConsoleA
;--- zakoñczenie procesu ---------
	invoke ExitProcess, 0	; wywo³anie funkcji ExitProcess
	
	main ENDP
_TEXT	ENDS    
END main

