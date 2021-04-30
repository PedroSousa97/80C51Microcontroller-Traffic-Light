#include <reg51.h> 

#define Tempo 5000 			//Constante que corresponde ao n�mero de contagens equivalentes a 1segundo (5000*200us = 1s)

sbit P3_verde = P2^3;		//Pin correspondente � luz verde do sem�foro dos pe�es

bit botao = 0;		//Bit que ser� utilizado para detetar o click do bot�o B3

unsigned long contador = 0;					//Contador que ser� utilizado para contar cada segundo utilizando o timer0
unsigned long contador_botao = 0;		//Contador que ser� utilizado para contar os 5 segundos de mudan�a de sinal quando o bot�o B3 � pressionado
int segundos = 0;										//Contador de segundos
int segundos_botao = 0;							//contador de segundos para a luz amarela de s2 quando b3 � pressionado
int inicia = 1;											//Vari�vel usada para referenciar em que estado os sem�foros se encontram


void Inicializacoes(void){
	//Configra��o do registo IE
	EA = 1;			//Enable global das interrup��es
	ET0 = 1;		//Enable do temporizador 0
	ET1 = 1;		//Enable do temporizador 1
	EX0 = 1;		//Enable da interrup��o externa 0 (Bot�o B3)
	
	//Configura��o do registo TMOD
	TMOD &= 0x00;		//Coloca o TMOD todo a 0 para o poder configurar
	TMOD |= 0x22;		//coloca o TMOD com configura��o do timer0 e timer1 a funcionar no modo2 (8bits) com auto-reload
	
	//Configura��o Timer0
	TL0=0x38;	// A funcionar no modo 2, os timers podem apenas representar valores com 8 bits -> 256 valor max
	TH0=0x38;	//timer0 -> 200us = 200 ciclos maquina de 1us. 256-200=56= 38H. Configuro desta forma o valor inicial do timer (38H) para realizar as 200 contagens
	
	//Configura��o Timer1
	TL1=0x38;	// A funcionar no modo 2, os timers podem apenas representar valores com 8 bits -> 256 valor max
	TH1=0x38;	//timer1 -> 200us = 200 ciclos maquina de 1us. 256-200=56= 38H. Configuro desta forma o valor inicial do timer (38H) para realizar as 200 contagens
	
	//Configura��o da Interrup��o externa pelo bot�o
	IT0 = 1;  		//Interrup��o0 ativa no falling edge
}



void main (void){
	P1 = 0xff;					//Coloca os outputs todos a 1
	P2 = 0xff;					//Coloca os outputs todos a 1
	
	Inicializacoes();		//Chama fun��o Inicializa��es para dar in�cio � configura��o dos registos
	
	while(1){											//Loop infinito
			TR0 = 1;									//Inicia temporizador0
			TR1 = 1;									//Inicia temporizador1
			if (inicia == 1){					//Inicia estado 1 (S1 e S2 verdes)
				while (segundos<=10){		//Durante 10s os sem�foros ter�o a seguinte configura��o: S1 e S2 verdes, S3 Vermelho e P3 Verde
					P1 = 0xdb;
					P2 = 0xf3;
					botao = 0;								//coloca botao a 0 para evitar este ficar ligado at� S3 ficar verde, ou seja, caso S3 n�o esteja verde, o click do bot�o n�o faz nenhuma a��o
					if (contador == Tempo){		//Conta tempo, a cada 5000 contadores corresponde 1s
						segundos++;							//incrementa segundos
						contador = 0;						//reinicia o contador
					}
				}
				inicia = 2;									//Referencia pr�ximo estado (S1 e S2 amarelos)
				segundos = 0;								//Reinicia segundos para o pr�ximo estado (S1 e S2 amarelos)
			}
			if (inicia == 2){							//Inicia estado 2 (S1 e S2 amarelo e P3 verde intermitente)
				while (segundos<=5){				//Durante 5s os sem�foros ter�o a seguinte configura��o: S1 e S2 amarelos, S3 Vermelho e P3 Verde intermitente
					P1 = 0xed;
					P2 = 0xf3;
					botao = 0;								//coloca botao a 0 para evitar este ficar ligado at� S3 ficar verde, ou seja, caso S3 n�o esteja verde, o click do bot�o n�o faz nenhuma a��o
					if (contador == Tempo){		//Conta tempo, a cada 5000 contadores corresponde 1s
						segundos++;							//incrementa segundos
						P3_verde = 1;						//A cada segundo que passa desliga a luz verde do sem�foro dos pe�es por um instante criando o efeito de intermit�ncia
						contador = 0;						//reinicia o contador
					}
				}
				inicia = 3;									//Referencia pr�ximo estado (S1 e S2 vermelhos, S3 verde e P3 vermelho)
				segundos = 0;								//Reinicia segundos para o pr�ximo estado
			}
			if (inicia == 3){							//Inicia estado 3 (S1, S2 e P3 vermelhos e S3 verde)
				while (segundos<=10){				//Durante 10s os sem�foros ter�o a seguinte configura��o: S1, S2 e P3 verdes, S3 Verde
					P1 = 0xf6;								//Durante este per�odo tenta tamb�m detetar o click do bot�o b3
					P2 = 0xee;
					if (botao == 1){					//se o bot�o for clicado a vari�vel botao fica a 1
						contador_botao=0;									//Reinicia o contador de tempo para o sinal amarelo de S3
						if (contador_botao == Tempo){			//Inicia a contagem dos 5 segundos em que o S3 deve ficar amarelo para haver a mudan�a de sinal para pe�es
							segundos_botao++;
							contador_botao= 0;
						}
						if(segundos_botao <= 5){			//Durante 5 segundos S3 fica amarelo, o estado do bot�o � reiniciado e inicia agora referencia para o estado 1 (S1,S2 e P3 verdes e S3 vermelho)
							P2 = 0xed;
							botao = 0;
							inicia = 1;
						}
						break;
					}
					if (contador == Tempo){				//Conta tempo, a cada 5000 contadores corresponde 1s
					segundos++;										//incrementa segundos
					contador = 0;									//reinicia o contador
					}
				}
				inicia = 4;									//Referencia pr�ximo estado (S1 e S2 vermelhos, S3 amarelo)
				segundos = 0;								//Reinicia segundos para o pr�ximo estado
			}
			if (inicia == 4){
				while (segundos<=5){				//Durante 5 segundos S3 fica amarelo at� reiniciar todo o ciclo infinito
					P1 = 0xf6;
					P2 = 0xed;
					botao = 0;								//coloca botao a 0 para evitar este ficar ligado at� S3 ficar verde, ou seja, caso S3 n�o esteja verde, o click do bot�o n�o faz nenhuma a��o
					if (contador == Tempo){		//Conta tempo, a cada 5000 contadores corresponde 1s
					segundos++;								//incrementa segundos
					contador = 0;							//reinicia o contador
					}
				}
				segundos = 0;								//Reinicia segundos para o pr�ximo estado
				inicia = 1;									//Referencia pr�ximo estado (S1 e S2 verdes, S3 vermehlo e P3 verde), ou seja que corresponde ao reiniciar deste ciclo infinito
			}
	}
}

void interrupt_botao(void) interrupt 0{			//Quando se d� uma interrup��o externa 0, neste caso o click do bot�o, a vari�vel botao fica a 1
	
	if (botao == 0){
		botao = 1;
	}
	
}

void interrupt_timer0(void) interrupt 1{		//Como este modo � com auto-reload aqui s� � necess�rio incrementar o contador quando existe interrup��o do timer por overflow, o mesmo reinicia automaticamente
	contador++;
}

void interrupt_timer1(void) interrupt 3{		//Como este modo � com auto-reload aqui s� � necess�rio incrementar o contador quando existe interrup��o do timer por overflow, o mesmo reinicia automaticamente
	contador_botao++;
}