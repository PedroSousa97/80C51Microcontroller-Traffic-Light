;Notas gerais:
;timer0 e timer1 irão funcionar no modo1 (16bits sem autoreload) 
;1 contagem = 1us, 10000 contagens = 10000us = 10ms,1000ms = 1s, ou seja 100*10ms
;10000d = 0x2710h
;65536-1000 = 55536d = D8F0H -> Valor de configuração inicial dos temporizadores para poder contar 10ms. 



;Definição de constantes
TempoL					EQU	0xF0		;Constante utilizada para iniciar e reiniciar o Timer (lower Byte)
TempoH					EQU 0xD8		;Constante utilizada para iniciar e reiniciar o Timer (Higher Byte)
Contagens_Por_segundo	EQU 0x64		;Constante correspondente ao número de contagens de 10ms para contar 1 segundo 100 = 64H
PortIn					EQU P3			;Pins de entrada onde irá conter o botão B3
PortIn_B3				EQU P3.2		;Pin individual do Botão B3
PortOut_S1_S2			EQU P1			;Pins de saída onde irá conter os semáforos S1 e S2
PortOut_S3_P3			EQU P2			;Pins de saída onde irá conter os semáforos S3 e P3
PortOut_P3_VERDE		EQU P2.3		;Pin individual da luz verde do semáforo dos peões, utilizado para criar intermitência
	
;Registos:
;R0 -> Vai conter o valor de contagens de 10ms necessárias para contar mais um segundo.
;R1 -> Representa o estado de s1 e s2, se s1 e s2 estiverem amarelos R1 = 1
;R2 -> B3
;R3 -> Valor a ser enviado para PortOut_S1_S2
;R4 -> Valor a ser enviado para PortOut_S3_P3
;A -> segundos passados

;Depois do reset
CSEG AT 0000H
	JMP Inicio
	
;Se ocorrer interrupção externa 0 pelo botão b3
CSEG AT 0003H
	JMP InterruptExt0
	
;Se ocorrer interrupção temporizador 1 pelo botão b3
CSEG AT 000BH
	JMP InterruptTemp0

	
;Inicia programa
CSEG AT 0050H
	Inicio:
		MOV SP, #7
		CALL Inicializacoes			;Chama inicializações e ativações
		CALL Ativa_interrupcoes
		CALL Ativa_Timers
	;Programa principal (ciclo infinito de funcionamento dos semáforos)
	Inicio_ciclo_infinito:
		MOV A, #10					;Reinicia o acumulador, utilizado para guardar segundos passados
	Ciclo_S1_S2:					;Ciclo de S1 e S2 verdes
		MOV R3, #0xdb				;Guarda em R3 e R4 o valor a ser enviado para P1 e P2 respetivamente
		MOV R4, #0xf3				;S1, S2 e P3 verdes, S3 Vermelho
		MOV PortOut_S1_S2, R3		;Coloca na Saída P1 o valor de R3
		MOV PortOut_S3_P3, R4		;Coloca na Saída P1 o valor de R4
		JNZ Ciclo_S1_S2				;Enquando Acumulador != 0, continua preso neste ciclo, o que significa que ainda não passou 10 segundos
		MOV A, #5					;Reinicia acumulador para os 5 segundos do amarelo de S1 e S2
		MOV R1, #1					;R1 = 1 indica que S1 e S2 irão ficar amarelos e inicia a intermitência de P3
	Ciclo_S1_S2_Amarelo:			;S1 e S2 amarelos e P3 intermitente (a intermitencia é criada na interrupção do timer0)
		MOV R3, #0xed				;Guarda em R3 e R4 o valor a ser enviado para P1 e P2 respetivamente
		MOV R4, #0xf3
		MOV PortOut_S1_S2, R3		;Coloca na Saída P1 o valor de R3
		MOV PortOut_S3_P3, R4		;Coloca na Saída P1 o valor de R4
		JNZ Ciclo_S1_S2_Amarelo		;Enquando Acumulador != 0, continua preso neste ciclo, o que significa que ainda não passou 5 segundos
		MOV A, #10					;Reinicia acumulador para os 10 segundos de S3 a verde
		MOV R1, #0					;R1 = 0 indica que S1 e S2 já não estão mais a amarelo, logo acaba intermitencia de P3
	Ciclo_S3:						;S3 Verde, restantes a vermelho
		MOV R3, #0xf6
		MOV R4, #0xee
		MOV PortOut_S1_S2, R3		;Coloca na Saída P1 o valor de R3
		MOV PortOut_S3_P3, R4		;Coloca na Saída P1 o valor de R4
		JNB PortIn_B3, Inicia_S3_amarelo	;Verifica se o botão foi carregado, se for esse o caso salta para o ciclo de S3 amarelo
		JNZ Ciclo_S3						;Caso contrário aguarda 10 segundos para então colocar S3 amarelo
	Inicia_S3_amarelo:
		MOV A, #5			;Reinicia acumulador para os 5 segundos do amarelo de S3
	S3_Amarelo:								
		MOV R3, #0xf6
		MOV R4, #0xed
		MOV PortOut_S1_S2, R3		;Coloca na Saída P1 o valor de R3
		MOV PortOut_S3_P3, R4		;Coloca na Saída P1 o valor de R4
		JNZ S3_Amarelo				;Enquando Acumulador != 0, continua preso neste ciclo, o que significa que ainda não passou 5 segundos
		JMP Inicio_ciclo_infinito	;Após o semáforo estar 5 segundos amarelo, reinicia todo o ciclo
		
	
	

;-------------------Rotinas---------------------------------

;-------------Rotina de inicializações----------------------
Inicializacoes:
	MOV R0,#Contagens_Por_segundo			;Inicia registos R0 -> Vai conter o valor de contagens de 10ms necessárias para contar mais um segundo.			
	MOV R2, #11111011b						;Guarda em R3 o estado de P3 com botão B3 = 0
	MOV R3, #0xff							;Apaga/Reinicia R3, registo que irá guardar os valores a enviar para P1
	MOV R4, #0xff							;Apaga/Reinicia R3, registo que irá guardar os valores a enviar para P1
	MOV A, #0								;Apaga/Reinicia o acomulador
	MOV PortIn, #0xff						;Apaga/Reinicia P3
	MOV PortIn, R2							;B3=0
	MOV PortOut_S1_S2, #0xff				;Apaga/Reinicia P1
	MOV PortOut_S3_P3, #0xff				;Apaga/Reinicia P2
	RET

;------------Rotina ativa interrupções------------------------
Ativa_interrupcoes:				;Ativa interrupção externa 0 e timer 0
	MOV IE, #10000011b
	SETB IT0
	RET
	
;------------Rotina ativa timers-----------------------------
Ativa_Timers:					;Configura timer no modo1 com valor inicial 55536d como referido anteriormente para poder contar 10ms
	MOV TMOD, #00000001b
	MOV TL0, #TempoL
	MOV TH0, #TempoH
	SETB TR0					;Ativa Timer0
	RET
	
;-------------Tratamento de interrupções----------------------

;-----------Interrupção externa por botão B3------------------
InterruptExt0:				;Se ocorrer uma interrupçao externa SET bit do botão B3
	SETB PortIn_B3
	RETI

;----------Interrupção por overflow do timer0----------------
InterruptTemp0:							
	MOV TL0, #TempoL					;Se ocorrer interrupçao do timer0 reinicia o valor inicial, pois o modo1 não tem auto-reload
	MOV TH0, #TempoH
	DJNZ R0, FIM_Int_temp0				;Se o contador de ciclos for diferente de 0, significa que ainda não contou um segundo então não realiza nenhuma operação
	CJNE R1, #1, Incrementa_normal		;Se R1 não for igual a 1 (S1 e S2 não estão a amarelo) então decrementa os segundos normalmente no acumulador e reinicia contagem
	MOV R0, #Contagens_Por_segundo		;Se R1 = 1 (S1 e S2 amarelos), então além de decrementar o acomulador e reiniciar a contagem, a cada segundo faz SETB da luz verde do semáforo P3
	DEC A								;Criando dessa forma a intermitência
	SETB PortOut_P3_VERDE
	RETI
	
	Incrementa_normal:					//Reinicia contagem e decrementa acumulador
	MOV R0, #Contagens_Por_segundo
	DEC A
	RETI
	FIM_Int_temp0:		//Simplesmente termina tratamento de interrupçao
	RETI
	

	
END
	
		