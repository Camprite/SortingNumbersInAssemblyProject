;Aplikacja korzystaj�ca z otwartego okna konsoli
;Aplikacja maj�ca na celu zapisywanie liczb do pliku, odczytywanie odraz sortowanie
;Przyj�ty algorytm sortowania: Bubble sort

.386
.MODEL flat, STDCALL
;OPTION LJMP ;Obs�uga d�u�szych skok�w

;--- stale ---
STD_INPUT_HANDLE                     equ -10
STD_OUTPUT_HANDLE                    equ -11
GENERIC_READ                         equ 80000000h
GENERIC_WRITE                        equ 40000000h
CREATE_NEW                           equ 1
CREATE_ALWAYS                        equ 2
OPEN_EXISTING                        equ 3
OPEN_ALWAYS                          equ 4
;--- prototypy ---
CharToOemA PROTO :DWORD,:DWORD
GetStdHandle PROTO :DWORD
ReadConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
WriteConsoleA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
CreateFileA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD 
GetCurrentDirectoryA PROTO :DWORD,:DWORD  
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
	hout	DD	?
	hinp	DD	?
	rangeFrom DD ?
	rangeTo DD ?
	range DD ?
	randomNumber DD ?
	numbersAmount DD ?
	openedFileHandle DD ?
	inputCharsReaded DD ?
	bytesWritten DD ?
	separator DD 3Bh


	naglow	DB	"Autor aplikacji  Dawid Borkowski.",0,0Ah
	testpath	DB	"C:\test.txt",0
	ALIGN	4	; przesuniecie do adresu podzielnego na 4
	rozmN	DD	$ - naglow	;liczba znak�w w tablicy


	getFilenameMsg DB 0Dh,0Ah,"Podaj nazwe pliku: ",0
	ALIGN	4
	sizeFilenameMsg	DD	$ - getFilenameMsg ;liczba znak�w w tablicy

	;	---		Opcje menu		---
	menuMsg1 DB 0Dh,0Ah,"Wybierz opcje: ",0
	ALIGN	4
	sizeMsg1	DD	$ - menuMsg1 ;liczba znak�w w tablicy

	menuMsg2 DB 0Dh,0Ah,"1. Losuj liczby i wpisz do pliku. ",0
	ALIGN	4
	sizeMsg2	DD	$ - menuMsg2 ;liczba znak�w w tablicy
	
	menuMsg3 DB 0Dh,0Ah,"2. Sortuj liczby.",0
	ALIGN	4
	sizeMsg3	DD	$ - menuMsg3 ;liczba znak�w w tablicy
	
	menuMsg4 DB 0Dh,0Ah,"3. Wypisz liczby z pliku. ",0
	ALIGN	4
	sizeMsg4	DD	$ - menuMsg4 ;liczba znak�w w tablicy	

	menuMsg5 DB 0Dh,0Ah,"4. Zako�cz program. ",0,0Ah
	ALIGN	4
	sizeMsg5	DD	$ - menuMsg5 ;liczba znak�w w tablicy

	menuInvalidArgument DB 0Dh,0Ah,"Nie rozpoznano argumentu, spr�buj ponownie.",0,0Ah
	ALIGN	4
	sizeMenuInvalidArgument	DD	$ - menuInvalidArgument ;liczba znak�w w tablicy
	
	rangeMsg1 DB 0Dh,0Ah,"Podaj zakres od: ",0,0Ah
	ALIGN	4
	sizeRangeMsg1 DD	$ - rangeMsg1 ;liczba znak�w w tablicy

	rangeMsg2 DB 0Dh,0Ah,"Podaj zakres do: ",0,0Ah
	ALIGN	4
	sizeRangeMsg2 DD	$ - rangeMsg2 ;liczba znak�w w tablicy
	

	rangeMsg3 DB 0Dh,0Ah,"Podaj ile liczb ma zosta� wylosowanych oraz zapisanych: ",0,0Ah
	ALIGN	4
	sizeRangeMsg3 DD	$ - rangeMsg3 ;liczba znak�w w tablicy


	menuOption	DB	3 dup(?)
	ALIGN	4
	sizeMenuOption	DD	$ - menuOption

	filenamePathBufor	DB	128 dup(?)
	ALIGN	4
	sizeFilenamePathBufor	DD	$ - filenamePathBufor 

	filenameBufor	DB	128 dup(?)
	ALIGN	4
	sizeFilenameBufor	DD	$ - filenameBufor 
	
	directoryNameBufor	DB	256 dup(?)
	ALIGN	4
	sizeDirectoryNameBufor	DD	$ - directoryNameBufor 
		
	inputBufor	DB	10 dup(?)
	ALIGN	4
	sizeInputBufor DD	$ - inputBufor 


	;---------stare;---------
	rout	DD	0 ;faktyczna liczba wyprowadzonych znak�w
	rinp	DD	0 ;faktyczna liczba wprowadzonych znak�w
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
    invoke 	WriteConsoleA, hout, OFFSET getFilenameMsg,sizeFilenameMsg,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET FilenameBufor, sizeFilenameBufor, OFFSET rinp,0	; wywo�anie funkcji ReadConsoleA
ENDM

getGetCurrentDirectoryMACRO MACRO directoryNameBufor:REQ, sizeDirectoryNameBufor:REQ
	invoke GetCurrentDirectoryA,  sizeDirectoryNameBufor, OFFSET directoryNameBufor
	;---------  Dodanie uko�nika na koniec (5C znak uko�nika w hexie)
	invoke lstrlenA, OFFSET directoryNameBufor
	MOV BYTE PTR[OFFSET directoryNameBufor + EAX],5Ch
ENDM

getFilenamePathMACRO MACRO directoryNameBufor:REQ, filenameBufor:REQ, filenamePathBufor:REQ, sizeFilenameBuforREQ, sizeDirectoryNameBufor:REQ
	;Makro pobieraj�ce nazwe pliku do wczytania
	getFilenameMACRO	filenameBufor, sizeFilenameBufor 
	
	;Makro pobieraj�ce nazwe bierz�cego katalogu
	getGetCurrentDirectoryMACRO		directoryNameBufor, sizeDirectoryNameBufor 
	
	;Kopiowanie do bufora docelowego scie�ki katalogu
	invoke lstrcpyA, OFFSET filenamePathBufor, OFFSET directoryNameBufor
	invoke lstrlenA, OFFSET directoryNameBufor
	
	;Konkatenacja z nazw� pliku do otworzenia
	invoke lstrcatA, OFFSET filenamePathBufor , OFFSET filenameBufor

ENDM

getFileInputHandlerMACRO MACRO filenamePathBufor:REQ, openedFileHandle:REQ

	;Pobanie uchwytu do pliku
	invoke CreateFileA, OFFSET filenamePathBufor, GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	MOV openedFileHandle, EAX
ENDM

printFileMACRO MACRO openedFileHandle:REQ

	invoke ReadFile, openedFileHandle, inputBufor, 1, inputCharsReaded, 0

ENDM

getNumberRangeMACRO MACRO

	;Pobranie warto�ci od
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg1,sizeRangeMsg1,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV rangeFrom, EAX

	;Pobranie warto�ci do
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg2,sizeRangeMsg2,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV rangeTo, EAX

	;Pobranie warto�ci ile
	invoke 	WriteConsoleA, hout, OFFSET rangeMsg3,sizeRangeMsg3,OFFSET rout,0
	invoke ReadConsoleA, hinp, OFFSET bufor, rbuf, OFFSET rinp, 0
	push OFFSET bufor
	call ScanInt
	MOV numbersAmount, EAX
ENDM

saveRandomNumbersInFile MACRO
	invoke GetTickCount ;zwraca w czas w milisekundach od ostatniego uruchomienia systemu
	invoke nseed,EAX; ustawienie warto�ci inicuj�cej generator liczb pseudolosowych
	
	MOV EAX, rangeTo
	SUB EAX, rangeFrom
	MOV range, EAX

	MOV ECX, numbersAmount

	;saveNumber:
	
	invoke nrandom,range ;zwraca w eax liczb� z zakresu 0-zakres
	ADD EAX, rangefrom ;Dodanie przesuniecia od zera
	;mov randomNumber,EAX

	invoke dwtoa, EAX, OFFSET  bufor;
	 
	invoke WriteFile, openedFileHandle, OFFSET bufor, EAX, bytesWritten,0
	invoke WriteFile, openedFileHandle, OFFSET separator, 2, bytesWritten,0

	;loop saveNumber
	invoke CloseHandle, openedFileHandle
ENDM

main proc
;--- pobranie uchwyt�w do wyj i wej
	ReturnDescryptor STD_OUTPUT_HANDLE, hout ;przyk�ad u�ycia makra
	ReturnDescryptor STD_INPUT_HANDLE, hinp ;przyk�ad u�ycia tego samego makra z innymi parametrami
;--------- konwersja znak�w wiadomo�ci na polskie znaki ---------
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
;------ wy�wietlenie autora ---------
    invoke 	WriteConsoleA, hout, OFFSET naglow,rozmN,OFFSET rout,0 

;------ p�tla menu ---------
menuLoop:

	;Wypisanie na konsole tre�ci z bufora menuMsg
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

	;Pobranie nazwy pliku
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor
	
	;Pobranie uchwytu do pliku
	getFileInputHandlerMACRO filenamePathBufor, openedFileHandle


	;Wypisanie pliku
	;printFileMACRO openedFileHandle
	
	invoke CloseHandle, openedFileHandle
	JMP menuLoop

	;--------------------------------------------LOSOWANIE CASE--------------------------------------------
	losujLiczby:		

	;Pobranie nazwy pliku
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor
	
	;Pobranie uchwytu do pliku
	getFileInputHandlerMACRO filenamePathBufor, openedFileHandle
	
	invoke CreateFileA, OFFSET testpath, GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	MOV openedFileHandle, EAX
	invoke WriteFile, openedFileHandle, OFFSET separator, 2, bytesWritten,0
	;Pobranie zakresu do losowania

	;getNumberRangeMACRO

	;saveRandomNumbersInFile

	invoke CloseHandle, openedFileHandle
	JMP menuLoop

	;--------------------------------------------SORTOWANIE CASE--------------------------------------------
	sortujLiczby:
	getFilenamePathMACRO	 directoryNameBufor, filenameBufor, filenamePathBufor,sizeFilenameBufor,sizeDirectoryNameBufor

	invoke CloseHandle, openedFileHandle
	JMP menuLoop




;--- wy�wietlenie wyniku ---------
	invoke	WriteConsoleA, hout, OFFSET bufor, rinp, OFFSET rout, 0; wywo�anie funkcji WriteConsoleA
;--- zako�czenie procesu ---------
	invoke ExitProcess, 0	; wywo�anie funkcji ExitProcess
	
	main ENDP
_TEXT	ENDS    
END main

