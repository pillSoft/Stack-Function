# Salani Lorenzo: lorenzo.salani@stud.unifi.it
# Fagioli Giulio: giulio.fagioli@stud.unifi.it	
# Buonanno Cecilia: cecilia.buonanno@stud.unifi.it
.data

jump_table: .space 16 # jump table array a 4 word che verra' instanziata dal main con gli indirizzi delle label che chiameranno le corrispondenti procedure

p1: .asciiz  "Trovata una lerrera"
cont:	.asciiz  "File contents: "
errore:	.asciiz  "File contents: "

buffer:   .space 1024	# Area di memoria per contenere la stringa letta
idx: 	  .word 2 	# Indice globale per scorrere la stringa
indent:   .word 0	# Nummero delle indentazioni

#Stringhe di errore
divzero: .asciiz "Impossibile eseguire una divisone per zero."	
fnf:	.ascii  "File non trovato o si è verificato un errore nella lettura di "
nomefile: .asciiz "chiamate.txt"	# Nome del file

#Stringhe di output
stampafreccie: .asciiz "--> "
stampasommareturn: .asciiz "<-- somma-return("
stampaprodottoreturn: .asciiz "<-- prodotto-return("
stampasottrazionereturn: .asciiz "<-- sottrazione-return("
stampadivisionereturn: .asciiz "<-- divisione-return("
parentesi: .asciiz ")"
tab : .ascii "	"

.text
.globl main
main:
	la $t1, jump_table	#Caricamento indirizzo jumptable 
  	la $t0, somma		#Caricamento indirizzo operazione somma 		
  	sw $t0, 0($t1)
   	la $t0, prodotto	#Caricamento indirizzo operazione prodotto 
  	sw $t0, 4($t1)
  	la $t0, sottrazione	#Caricamento indirizzo operazione sottrazione 
  	sw $t0, 8($t1)
      	la $t0, divisione	#Caricamento indirizzo operazione divisione 
      	sw $t0,12($t1)
# Apertura del file
	li	$v0, 13		# Syscall apertura file
	la	$a0, nomefile	# Caricamento nome del file
	li	$a1, 0		# Read-only Flag
	li	$a2, 0		# (ignored)
	syscall
	move	$t6, $v0	# Save File Descriptor
	blt	$v0, 0, errfile	# Goto Error
# Lettura del file 
	li	$v0, 14		# Read File Syscall
	move	$a0, $t6	# Load File Descriptor
	la	$a1, buffer	# Load Buffer Address
	li	$a2, 1024	# Buffer Size 
	syscall
# Chiusura del file 
	li	$v0, 16		# Close File Syscall
	move	$a0, $t6	# Load File Descriptor
	syscall	
	
# Controllo della prima operazione da fare e richiamo della relativa procedura
	lw $t0, idx		# Caricamento in $t0 del contatore idx
	
	la $a1,buffer		# Caricamento in $a1 del buferr letto	
	add $a1,$a1,$t0		# Aggiunta ad $a1 dell'indice idx per leggere l'idx-esimo carattere di buffer
	lb $a0,($a1) 		# Lettura del primo byte di $a1 

	jal switchoperazione	# Richiamo della funzione switchoperazione con passato come parametro il carattere su cui effettuare il controllo 
	
	move $t0,$v0    	# Salvataggio di $v0 per andare a capo dopo
	
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stampa carattere
	syscall
	
	move $a0, $t0		# Caricamento risultato per in $a0 per la stampa
	li $v0, 1     		# Syscall stampa intero
	syscall
	
	j fine			# Fine programma
	
somma:
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	jal stampaTab		# Richiamo della funzione per stampare le indentazioni

	lw $t0,idx		# Caricamento della posizione della terza lettera dell'operazione 
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $t0,0($sp)		# Salvataggio del valore di idx perchè dalla funzione successiva sarà modificato
	
	li $a0,'('		# Caricamento del carattere da cercare in $a0
	jal ricerca		# Ricerca del carattere (
	
	jal trovafine		# Funzione che restituisce la posizione della parentesi ')' corrispondente 

	move $a1,$v0		# Caricamento della posizione finale della stringa da stampare 

	lw $a0,0($sp)		# Caricamento della posizione della terza lettera della stringa
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	addi $a0,$a0,-2		# Posizione iniziale della stringa da stampare 
	
	jal stampaIntervallo	# Funzione di stampa della stringa su cui eseguiamo l'operazione
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, 1	# Aumento delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stampa carattere
	syscall
	
	jal parse    		# Richiamo di parse per la lettura dei due valori
	
	add $t1, $v0, $v1 	# Somma dei due valori di ritorno, salvataggio temporaneo del risultato in $t1
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, -1	# Decremnto delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	jal stampaTab		# Funzione che stampa un numero di indentazioni pari al valore di indent
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, stampasommareturn	# Caricamento stringa da stampare
	syscall
	li	$v0, 1		# Syscall stampa intero
	move	$a0, $t1	# Caricamento valore da stampare
	syscall
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, parentesi	# Caricamento stringa da stampare
	syscall
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stama carattere
	syscall
	
	move $v0, $t1		# Caricamento del risultato dell'operazione in $v0	
	jr $ra			# Ritorno al chiamante

prodotto:
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	jal stampaTab		# Richiamo della funzione per stampare le indentazioni

	lw $t0,idx		# Caricamento della posizione della terza lettera dell'operazione 
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $t0,0($sp)		# Salvataggio del valore di idx perchè dalla funzione successiva sarà modificato
	
	li $a0,'('		# Caricamento del carattere da cercare in $a0
	jal ricerca		# Ricerca del carattere (
	
	jal trovafine		# Funzione che restituisce la posizione della parentesi ')' corrispondente 

	move $a1,$v0		# Caricamento della posizione finale della stringa da stampare 

	lw $a0,0($sp)		# Caricamento della posizione della terza lettera della stringa
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	addi $a0,$a0,-2		# Posizione iniziale della stringa da stampare 
	
	jal stampaIntervallo	# Funzione di stampa della stringa su cui eseguiamo l'operazione
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, 1	# Aumento delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stampa carattere
	syscall
	
	jal parse    		# Richiamo di parse per la lettura dei due valori
	
	mul $t1, $v0, $v1 	# Somma dei due valori di ritorno, salvataggio temporaneo del risultato in $t1
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, -1	# Decremnto delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	jal stampaTab		# Funzione che stampa un numero di indentazioni pari al valore di indent
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, stampaprodottoreturn	# Caricamento stringa da stampare
	syscall
	li	$v0, 1		# Syscall stampa intero
	move	$a0, $t1	# Caricamento valore da stampare
	syscall
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, parentesi	# Caricamento stringa da stampare
	syscall
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stama carattere
	syscall
	
	move $v0, $t1		# Caricamento del risultato dell'operazione in $v0	
	jr $ra			# Ritorno al chiamante
	
	
sottrazione:
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	jal stampaTab		# Richiamo della funzione per stampare le indentazioni

	lw $t0,idx		# Caricamento della posizione della terza lettera dell'operazione 
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $t0,0($sp)		# Salvataggio del valore di idx perchè dalla funzione successiva sarà modificato
	
	li $a0,'('		# Caricamento del carattere da cercare in $a0
	jal ricerca		# Ricerca del carattere (
	
	jal trovafine		# Funzione che restituisce la posizione della parentesi ')' corrispondente 

	move $a1,$v0		# Caricamento della posizione finale della stringa da stampare 

	lw $a0,0($sp)		# Caricamento della posizione della terza lettera della stringa
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	addi $a0,$a0,-2		# Posizione iniziale della stringa da stampare 
	
	jal stampaIntervallo	# Funzione di stampa della stringa su cui eseguiamo l'operazione
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, 1	# Aumento delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stampa carattere
	syscall
	
	jal parse    		# Richiamo di parse per la lettura dei due valori
	
	sub $t1, $v0, $v1 	# Somma dei due valori di ritorno, salvataggio temporaneo del risultato in $t1
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, -1	# Decremnto delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	jal stampaTab		# Funzione che stampa un numero di indentazioni pari al valore di indent
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, stampasottrazionereturn	# Caricamento stringa da stampare
	syscall
	li	$v0, 1		# Syscall stampa intero
	move	$a0, $t1	# Caricamento valore da stampare
	syscall
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, parentesi	# Caricamento stringa da stampare
	syscall
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stama carattere
	syscall
	
	move $v0, $t1		# Caricamento del risultato dell'operazione in $v0	
	jr $ra			# Ritorno al chiamante

divisione:
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti

	jal stampaTab		# Richiamo della funzione per stampare le indentazioni

	lw $t0,idx		# Caricamento della posizione della terza lettera dell'operazione 
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $t0,0($sp)		# Salvataggio del valore di idx perchè dalla funzione successiva sarà modificato
	
	li $a0,'('		# Caricamento del carattere da cercare in $a0
	jal ricerca		# Ricerca del carattere (
	
	jal trovafine		# Funzione che restituisce la posizione della parentesi ')' corrispondente 

	move $a1,$v0		# Caricamento della posizione finale della stringa da stampare 

	lw $a0,0($sp)		# Caricamento della posizione della terza lettera della stringa
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	addi $a0,$a0,-2		# Posizione iniziale della stringa da stampare 
	
	jal stampaIntervallo	# Funzione di stampa della stringa su cui eseguiamo l'operazione
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, 1	# Aumento delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stampa carattere
	syscall
	
	jal parse    		# Richiamo di parse per la lettura dei due valori
	
	beq $v1, 0, errdivzero
	
	div $t1, $v0, $v1 	# Somma dei due valori di ritorno, salvataggio temporaneo del risultato in $t1
	
	lw $t0, indent		# Caricamento della variabile che conta le indentazioni da fare
	addi $t0, $t0, -1	# Decremnto delle indentazioni di 1 dopo aver stampato un intervallo
	sw $t0, indent		# Salvataggio del nuovo valore della variabile
	
	jal stampaTab		# Funzione che stampa un numero di indentazioni pari al valore di indent
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, stampadivisionereturn	# Caricamento stringa da stampare
	syscall
	li	$v0, 1		# Syscall stampa intero
	move	$a0, $t1	# Caricamento valore da stampare
	syscall
	li	$v0, 4		# Syscall stampa stringa
	la	$a0, parentesi	# Caricamento stringa da stampare
	syscall
	li $a0,10	 	# Caricamento carattere New Line per andare a capo
	li $v0, 11      	# Syscall stama carattere
	syscall
	
	move $v0, $t1		# Caricamento del risultato dell'operazione in $v0	
	jr $ra			# Ritorno al chiamante

parse:
	lw $t0,idx		# Caricamento in $t0 del contatore idx
	la $a1,buffer		# Caricamento in $a1 del buferr letto	
	add $a1,$a1,$t0		# Aggiunta ad $a1 dell'indice idx per leggere l'idx-esimo carattere di buffer
	lb $a0,($a1) 		# Lettura del primo byte di $a1
	
	li $t3,0		# Inizializzazione con 0 del registro $t3 per controllare il segno 
	beq $a0,'+', primoPiu	# Controllo se il primo carattere è un +
	beq $a0,'-', primoMen	# Controllo se il primo carattere è un -
	blt $a0,'0', primalettera	# Se il codice ascci del carattere è minore di quello di '0' salta all'etichetta primalettera
	bgt $a0,'9', primalettera	# Se il codice ascci di '9' è minore di quello del carattere salta all'etichetta primalettera		
	j primonumero		# Se il carattere è un numero salta all'etichetta primonumero
	primoMen:
	li $t3,1		# Se il carattere è un + imposta $t3 ad 1 
	primoPiu:
	addi $a1, $a1, 1  	# Aumenta il puntatore al buffer di 1
	# A questo punto $a1 punta ad un numero ed è specificato in $t3 il suo segno
	
primonumero:
	
	li $t0,10		# Caricameto del valore 10 in $t0 per essere usato nel ciclo successivo
	li $s2,0		# Azzeramento resistro 
	caricacifre1:
  		lb $t1, ($a1)       	# Caricamento cifra in $t1
  		blt $t1, 48, cifrecaricate1    	# Se $t1 non è un numero tutte le cifre sono state caricate, quindi si esce
  		bgt $t1, 57, cifrecaricate1   	# Se $t1 non è un numero tutte le cifre sono state caricate, quindi si esce
  		addi $t1, $t1, -48   	# Conversion di $t1 da acsii in decimale
  		mul $s2, $s2, $t0    	# Moltiplicazione del numero per 10 
  		add $s2, $s2, $t1    	# Aggiunta della cifra al numero come unità
  		addi $a1, $a1, 1     	# Incremento del'indirizzo di buffer
  		j caricacifre1           # Salto all'etichetta caricacifre
 	cifrecaricate1:
	
	beq $t3,0, primoPositivo	# Se $t3 = 0 il numero non era preceduto da un - quindi proseguiamo con il salvataggio	
	sub $s2,$zero,$s2	# Se $t3 = 1 il numero era preceduto da un - quindi effettuiamo un sottrazione rendendolo negativo
	
	primoPositivo:
	
	addi $sp,$sp,-4		# Disallocazione di 4 byte dello stack pointer
	sw $s2,0($sp)		# Inserimento nello stack del numero trovato
	
	j secondocarattere  	# Controllo del secondo parametro dell'operazione
	
primalettera:

	addi $t0,$t0,2		# Aggiunta di 2 a $t0 ce conteneva il valore di idx 
	sw $t0,idx		# Salvataggio del nuovo valore di idx
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti
	
	lw $t0,idx		# Caricamento in $t0 del contatore idx
	la $a1,buffer		# Caricamento in $a1 del buferr letto	
	add $a1,$a1,$t0		# Aggiunta ad $a1 dell'indice idx per leggere l'idx-esimo carattere di buffer
	lb $a0,($a1) 		# Lettura del primo byte di $a1
	
	jal switchoperazione	# Richiamo della funzione switchoperazione con passato come parametro il carrattere su cui effettuare il controllo 
	   
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $v0,0($sp)		# Salvataggio nello stack del risultato dell'operazione eseguita nella funzione switchoperazione

secondocarattere:
	addi $sp,$sp,-4		# Disallocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti
	
	li $a0,','		# Caricamento del carattere da cercare in $a0
	jal ricerca		# Ricerca del carattere
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Rimozione dei 4 byte precedentemente allocati

	lw $t0,idx		# Caricamento in $t0 del contatore idx
	
	la $a1,buffer		# Caricamento in $a1 del buferr letto	
	add $a1,$a1,$t0		# Aggiunta ad $a1 dell'indice idx per leggere l'idx-esimo carattere di buffer
	lb $a0,($a1) 		# Lettura del primo byte di $a1
	
	li $t3,0		# Inizializzazione con 0 del registro $t3 per controllare il segno 
	beq $a0,'+', secondoPiu	# Controllo se il primo carattere è un +
	beq $a0,'-', secondoMeno	# Controllo se il primo carattere è un -
	blt $a0,'0', secondaLettera	# Se il codice ascci del carattere è minore di quello di '0' salta all'etichetta primalettera
	bgt $a0,'9', secondaLettera	# Se il codice ascci di '9' è minore di quello del carattere salta all'etichetta primalettera		
	j secondoNumero		# Se il carattere è un numero salta all'etichetta primonumero
	secondoMeno:
	li $t3,1		# Se il carattere è un + imposta $t3 ad 1 
	secondoPiu:
	addi $a1, $a1, 1  	# Aumenta il puntatore al buffer di uno
	# A questo punto $a1 punta ad un numero ed è specificato in $t3 il suo segno
	
secondoNumero:

	li $t0,10		# Caricameto del valore 10 in $t0 per essere usato nel ciclo successivo
	li $s2,0		# Azzeramento resistro 
	caricacifre2:
  		lb $t1, ($a1)       	# Caricamento cifra in $t1
  		blt $t1, 48, cifrecaricate2    	# Se $t1 non è un numero tutte le cifre sono state caricate, quindi si esce
  		bgt $t1, 57, cifrecaricate2   	# Se $t1 non è un numero tutte le cifre sono state caricate, quindi si esce
  		addi $t1, $t1, -48   	# Conversion di $t1 da acsii in decimale
  		mul $s2, $s2, $t0    	# Moltiplicazione del numero per 10 
  		add $s2, $s2, $t1    	# Aggiunta della cifra al numero come unità
  		addi $a1, $a1, 1     	# Incremento del'indirizzo di buffer
  		j caricacifre2           # Salto all'etichetta caricacifre
 	cifrecaricate2:
	
	beq $t3,0, secondoPositivo	# Se $t3 = 0 il numero non era preceduto da un - quindi proseguiamo con il salvataggio	
	sub $s2,$zero,$s2	# Se $t3 = 1 il numero era preceduto da un - quindi effettuiamo un sottrazione rendendolo negativo
	secondoPositivo:
	
	lw $v0,0($sp)		# Recupero del primo operando e salvataggio di esso in $v0
	addi $sp,$sp,4 		# Rimozione di 4 byte allo stack pointer
	
	move $v1,$s2    	# Salvataggio del secondo operando in $v1
	
	j fineparse		# Fine della funzione parse
	
secondaLettera:
	
	addi $t0,$t0,2		# Aggiunta di 2 a $t0 ce conteneva il valore di idx 
	sw $t0,idx		# Salvataggio del nuovo valore di idx
	
	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti
	
	lw $t0,idx		# Caricamento in $t0 del contatore idx
	la $a1,buffer		# Caricamento in $a1 del buferr letto	
	add $a1,$a1,$t0		# Aggiunta ad $a1 dell'indice idx per leggere l'idx-esimo carattere di buffer
	lb $a0,($a1) 		# Lettura del primo byte di $a1
	
	jal switchoperazione	# Richiamo della funzione switchoperazione con passato come parametro il carrattere su cui effettuare il controllo 
	   
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	move $v1,$v0		# Spostamento del risultato dell'operazione in $v1 per lasciare $v0 al primo operando
	
	lw $v0,0($sp)		# Caricamento del primo operando in $v0 precedentemente salvato nello stack
	addi $sp,$sp,4 		# Disallocazione di 4 byte dello stack pointer
	
fineparse:									
	jr $ra			# Ritorno al chiamante
	
# Parametri : $a0, carattere da ricercare 
# Funzione che cerca il valore contenuto in $a0 e salva in idx la sua posizione + 1 
ricerca:			
	la $t1,buffer		# Carica la stringa letta da file in $t0
	lw $a1,idx  		# Carica l'indice idx in $a1
	move $t6,$a0 		# Spostamento carattere in $t6
	move $t5,$a1 		# Spostamento indice in $t5
	add $t1,$t1,$a1		# Aggiunta dell'indice alla stringa per far iniziare la ricerca da esso
loop:# Ciclo che legge ogni carattere
	lbu $t2,($t1)		# Caricamento in $t2 del primo byte del buffer
	beq $t2,$t6,trovato 	# Se la lettera è uguale alla mia target vado all'etichetta trovato
	beq $t2,$zero,errricerca# Se è uguale a 0 vuol dire che la stringa è finita
	add $t1,$t1,1 		# Aumento dell'indice che scorre la stringa
	addi  $t5, $t5, 1      	# Aggiorno il counter delle posizioni gia visitate
	j loop			# Salto all'etichetta loop
trovato: #  Il carattere è stato trovato 
	addi $t5,$t5,1 		# Aggiunge 1 alla posizione trovata
	sw $t5, idx		# Salva in idx il valore trovato
	jr $ra			# Ritorno al chiamante
	
# Parametri : $a0, carattere che identifica una delle operazioni
# Funzione in base al parrametro richiama un operazione attraverso la jumptable
switchoperazione:
      	beq    $a0, 'm', jsomma  		# Confronti per saltare all'etichetta corrispondente all'operazione da eseguire
      	beq    $a0, 'v', jdivisione  	
      	beq    $a0, 'o', jprodotto  	
      	beq    $a0, 't', jsottrazione 	
jsomma:			
      	li $t0,1		# Salvataggio del valore corrispondente alla procedura somma nella jumptable
      	j branch_case	
jprodotto:
      	li $t0,2		# Salvataggio del valore corrispondente alla procedura prodotto nella jumptable
      	j branch_case
jsottrazione:
      	li $t0,3		# Salvataggio del valore corrispondente alla procedura sottrazione nella jumptable
      	j branch_case
jdivisione:
      	li $t0,4		# Salvataggio del valore corrispondente alla procedura divisione nella jumptable
      	j branch_case
branch_case:
      	addi $t0, $t0, -1  	# Si sottrae 1 dalla scelta perchè prima azione nella jump table (in posizione 0) corrisponde alla prima scelta del case
      	add $t0, $t0, $t0	# Calcolo della $t0 * 2
      	add $t0, $t0, $t0	# Calcolo della $t0 * 4
	la $t1, jump_table 	# Salvataggio dell'indirizzo della jump_table in $t1
      	add $t0, $t0, $t1 	# Somma dell'indirizzo della jump_table l'offset calcolato 
	lw $t0, 0($t0)    	# $t0 indirizzo a cui devo saltare  
      	
      	addi $sp,$sp,-4		# Allocazione di 4 byte dello stack pointer
	sw $ra,0($sp)		# Salvataggio di $ra nello stack per recuperarlo dopo il lancio delle procedure seguenti
	
	jalr $t0 		# Salto all'indirizzo calcolato
	
	lw $ra,0($sp) 		# Recupero di $ra dallo stack
	addi $sp,$sp,4		# Disallocazione di 4 byte dello stack pointer
	
	jr $ra			# Ritorno al chiamante


# Parametri : a0 posizione di partenza, a1 posizione di arrivo
# Funzione per stampare 
stampaIntervallo:
	la $t1,buffer		# Caricamento in $t1 del buffer per la stampa
	add $t1, $t1, $a0	# Aggiunta della posizione iniziale al buffer per iniziare la stampa da essa
	move $t3,$a0		# Savataggio della posizione iniziale in $t3
	li $v0, 4		# Syscall stampa stringa con la freccia
	la $a0, stampafreccie	# Caricamento stringa da stampare
	syscall			
loopt:				
	lb $t2,($t1)		# Caricamento in $t2 del primo byte da stampare
	beq $t3,$a1,fineStampaIntervallo # Se la $t3 è uguale alla posizione dii arrivo vado all'etichetta fineStampaIntervallo
	move $a0,$t2		# Spostamento del carattere in $a0 per essere stampato
	li $v0,11		# Syscall stampa carattere
	syscall
	addi $t1,$t1,1 		# Incremento del puntatore al buffer
	addi  $t3, $t3, 1      	# Incremento del numero di posizioni visitate
	j loopt
fineStampaIntervallo:
	jr $ra			# Ritorno al chiamante


# Funzione per stampare un numero di tab pari al valore della variabile indent
stampaTab:
	lw $t0,indent		# Caricamento del valore di indent in $t0
loopTab:		
	beq $t0, $zero, fineTab	# Quando $t0 è uguale a 0 abbiamo stampato tutti i tab richiesti e usciamo
	li $a0,9		# Caricamento carattere 9 (TAB) in $a0 per essere stampato
	li $v0,11		# Syascall stampa carattere
	syscall			
	addi $t0,$t0,-1		# Diminuzione di 1 del contatore dei tab
	j loopTab		# Salto a loopTab
fineTab:
	jr $ra			# Ritorno al chiamante
	
# Funzione che a partire dalla posizione idx trova la parentesi ')' corrispondente alla funzione in cui ci troviamo
# Quando trova una parentesi '(' aumenterà il registro $t3
trovafine:
	la $t1,buffer		# Caricamento in $t1 del buffer per la ricerca
	li $t6,'(' 		# Caricamento valore '(' per le ricerche 
	li $t4,')' 		# Caricamento valore ')' per le ricerche 
	lw $t5,idx		# Caricamento posizione successiva alla parentesi '(' corrispondente alla funzione in cui ci troviamo
	li $t3,1 		# Inizializzazione $t3 con 1 perchè abbiamo già superato la pria ma parentesi '('
	add $t1,$t1,$t5		# Aggiunta di idx a $t1 per far puntare $t1 all'idx-esimo carattere di buffer
looptf:
	lb $t2,($t1)			# Caricamento in $t2 del primo byte 
	beq $t2,$zero,finetrovafine 	# Se $t2 è uguale a 0 la stringa è finita
	beq $t3,$zero,finetrovafine 	# Se $t3 è uguale a 0 abbiamo trovato la posizione della parentesi '('
	beq $t2,$t6,apertura		# Se troviamo una '(' incrementiamo $t3	
	beq $t2,$t4,chiusura		# Se troviamo una ')' decrementiamo $t3	
increase:
	addi $t1,$t1,1 		# $t1 punta al carattere successivo di buffer
	addi  $t5, $t5, 1      	# Aumento del registro $t5 che alla fine conterrà la posizione del carattere cercato
	j looptf
apertura:
	addi  $t3, $t3, 1      	# Incremento contatore parentesi
	j increase
chiusura:
	addi    $t3, $t3, -1    	# Decremento contatore parentesi
	j increase
finetrovafine:
	move $v0,$t5		# Restituzone del registro $t5 che conterrà la posizione della ')'
	jr $ra			# Ritorno al chiamante

# Errori
errfile:
	li	$v0, 4		# Syscall stampa stringa 
	la	$a0, fnf	# Caricamento stringa 
	syscall
	j fine
	
errricerca:
	li	$v0, 4		# Syscall stampa stringa 
	la	$a0, fnf	# Caricamento stringa 
	syscall
	j fine
	
errdivzero:
	li	$v0, 4		# Syscall stampa stringa 
	la	$a0, divzero	# Caricamento stringa 
	syscall
	j fine
	
fine:
	li	$v0, 10		# Syscall fine programma
	syscall	
