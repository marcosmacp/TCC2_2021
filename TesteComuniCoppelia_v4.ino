//Codigo carro robotico Para comunicacao Coppelia
//
//******************************************************************************************
// Definicoes de Constantes
#define trig  13                 // Pino 13 Trigger
#define echo2 12                 // Pino 12 Echo Sensor 2 
#define echo1 11                 // Pino 11 Echo Sensor 1
#define trig2  10                 // Pino 10 Trigger  
#define ENA    9                 // Pino de habilitacao do motor A  
#define motorEsqTras    7                 // Pino de ativacao motor A no sentido Horario  
#define motorEsqFrente    6                 // Pino de ativacao motor A no sentido Anti-horario   
#define motorDirTras    5                 // Pino de ativacao motor B no sentido Horario   
#define motorDirFrente    4                 // Pino de ativacao motor B no sentido Anti-horario  
#define ENB    3                 // Pino de habilitacao do motor B 

//******************************************************************************************
// Prototipos de Funcoes Auxiliares
// Utilizado para criar cada funcao, para poder declara-la e acessa-la posteriormente
int sensor1(void);               // Retorna a distancia do obstaculo 1 em milimetros
int sensor2(void);               // Retorna a distancia do obstaculo 2 em milimetros
int procuraCaminho(unsigned char, unsigned int);

void enviaString(unsigned char); // Envia a string para a Serial, com os dados necessários separados por vírgula e concatenados
void movAvante(unsigned char);   // Aciona motores para avancar em linha reta
void movRe(unsigned char);       // Aciona motores para recuar  em curva
void movCurvaDireita(unsigned char);      // Aciona motores para desviar a direita
void movCurvaEsquerda(unsigned char);     // Aciona motores para desviar a esqueda

//******************************************************************************************
// Variaveis Globais
String stringAux, leituraSerial, enviaSerial;
int dist1, dist2, veloc, tempo, modo;
char tecla, direcao = 'w';

//******************************************************************************************
// Configuracoes de Inicializacao do Arduino
void setup()
{
  Serial.begin(9600); //115200 para o ESP32
  Serial.setTimeout(100); //Configura o tempo de leitura da Serial para 100ms, o padrao e 1000ms, ou 1s
  pinMode(trig,  OUTPUT);
  pinMode(trig2,  OUTPUT);
  pinMode(echo1, INPUT);
  pinMode(echo2, INPUT);
  pinMode(motorEsqTras, OUTPUT);
  pinMode(motorEsqFrente, OUTPUT);
  pinMode(motorDirTras, OUTPUT);
  pinMode(motorDirFrente, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
}

void loop() {

  dist1 = sensor1();
  dist2 = sensor2();

  enviaString();
  delay(100);

  if (Serial.available() > 0) // Verifica se algo foi recebido
  { // exemplo inicial da String a ser recebida: m,125,300,w\n
    leituraSerial = Serial.readStringUntil('\n'); //le o que e enviado pelo coppelia (via Serial)
    if (leituraSerial.startsWith("k")) { //modo automatico
      modo = 1;
    }
    else if (leituraSerial.startsWith("m")) { // modo manual
      modo = 2;
    }
    else if (leituraSerial.endsWith("p")) {
      modo = 0;
    }

    stringAux = leituraSerial.substring(2, 5); //separa a string recebida pegando 3 caracteres, como "125" na String inicial
    veloc = stringAux.toInt(); // converte a String separada para um inteiro (exemplo: 125)

    stringAux = leituraSerial.substring(6, 9); //separa a string recebida pegando 3 caracteres, como "100" na String inicial
    tempo = stringAux.toInt(); // converte a String separada para um inteiro (exemplo: 100)
    tecla = leituraSerial.charAt(10); //localiza a letra da posicao 10 na String inicial (exemplo: 'w')
  }

  if (modo == 1) { //modo AUTOMATICO
    if (tecla == 'q' || tecla == 'p'){
      parar();
    }
    else if (((dist1 == 0) && (dist2 == 0)) || ((dist1 + dist2) >= 250) || dist1 >=130 || dist2 >=130 ) { //130mm ou 13cm
      movAvante(veloc); // seguir em frente na velocidade recebida pela String
    }
    else //desvia de obstaculo
    {
      parar(); // parar o deslocamento para evitar colisao
      delay(tempo/2);
      movRe(veloc);
      delay(tempo);
      procuraCaminho(); //procura o caminho mais livre, para a direita ou esquerda
      delay(tempo/2);
    }
  }
  else if (modo == 2) //modo MANUAL
  {
    switch (tecla) { //verifica qual foi a tecla recebida na String
      case 'w': //direciona para frente
        movAvante(veloc);
        delay(tempo);
        break;
      case 's': //direciona para trás
        movRe(veloc);
        delay(tempo);
        break;
      case 'd': //direciona para direita
        movCurvaDireita(veloc);
        delay(tempo);
        break;
      case 'a': //direciona para esquerda
        movCurvaEsquerda(veloc);
        delay(tempo);
        break;
      case 'q': //comando de parada
        parar();
        break;
      default: //outros comandos
        parar();
        break;
    }
  }
  else
  {
    parar();
    limpaSerial();
  }
}

//******************************************************************************************
// Implementacoes das Funcoes Auxiliares do Projeto

void enviaString() //função para enviar os dados do Arduino em formato string
{
  Serial.print(dist1); //envia a leitura do sensor esquerdo
  Serial.print(","); // separa a informação por vírgula
  Serial.print(dist2); //envia a leitura do sensor direito
  Serial.print(","); // separa a informação por vírgula
  Serial.println(direcao); //envia a direção que o Arduino esta seguindo
}

int sensor1(void)
{
  digitalWrite(trig, HIGH); //inicia emissao de sinal ultrassonico 1
  delayMicroseconds(10); //aguarda 10seg
  digitalWrite(trig, LOW); //finaliza emissao de sinal ultrassonico 1
  return (10 * pulseIn(echo1, HIGH, 4500) / 58); // recebe a leitura do sinal ultrassonico 1 e converte para milimetros
}

int sensor2(void)
{
  digitalWrite(trig2, HIGH); //inicia emissao de sinal ultrassonico 2
  delayMicroseconds(10); //aguarda 10seg
  digitalWrite(trig2, LOW); //finaliza emissao de sinal ultrassonico 2
  return (10 * pulseIn(echo2, HIGH, 4500) / 58); // recebe a leitura do sinal ultrassonico 2 e converte para milimetros
}

void parar() // nenhum dos motores gira
{
  direcao = 'q';
  enviaString();
  digitalWrite(motorEsqTras, LOW);
  digitalWrite(motorEsqFrente, LOW);
  digitalWrite(motorDirTras, LOW);
  digitalWrite(motorDirFrente, LOW);
}

void movAvante(unsigned char vel) //ambos os motores giram para a frente do carro
{ //velocidade (vel) passado para poder fazer movimentos mais rapidos ou mais lentos
  direcao = 'w'; //seguir para frente
  enviaString(); //envia os dados via Serial, para leitura do Coppelia
  analogWrite(ENA, vel); //habilita o motor esquerdo na velocidade definida
  analogWrite(ENB, vel);//habilita o motor direto na velocidade definida

  digitalWrite(motorEsqTras, LOW); //indica o sentido da corrente para o motor esquerdo
  digitalWrite(motorEsqFrente, HIGH); 
  digitalWrite(motorDirTras, LOW); //indica o sentido da corrente para o motor direito
  digitalWrite(motorDirFrente, HIGH);
}

void movRe(unsigned char vel) //ambos os motores giram no sentido de re do carro
{
  direcao = 's';
  enviaString();
  analogWrite(ENA, vel);
  analogWrite(ENB, vel);

  digitalWrite(motorEsqTras, HIGH);
  digitalWrite(motorEsqFrente, LOW);
  digitalWrite(motorDirTras, HIGH);
  digitalWrite(motorDirFrente, LOW);
}

void movCurvaDireita(unsigned char vel) // motor esquerdo girando para frente e direito para tras, girando o carro para a direita
{
  direcao = 'd';
  enviaString();
  analogWrite(ENA, vel);
  analogWrite(ENB, vel);

  digitalWrite(motorEsqTras, LOW);
  digitalWrite(motorEsqFrente, HIGH);
  digitalWrite(motorDirTras, HIGH);
  digitalWrite(motorDirFrente, LOW);
}

void movCurvaEsquerda(unsigned char vel) // motor esquerdo girando para tras e direito para frente, girando o carro para a esquerda
{
  direcao = 'a';
  enviaString();
  analogWrite(ENA, vel);
  analogWrite(ENB, vel);

  digitalWrite(motorEsqTras, HIGH);
  digitalWrite(motorEsqFrente, LOW);
  digitalWrite(motorDirTras, LOW);
  digitalWrite(motorDirFrente, HIGH);
}

void procuraCaminho() //procurar menor caminho para o carro desviar de obstaculos e em seguida continuar seguindo em frente
{ // velocidade (vel) e tempo (temp) passados para poder fazer movimentos mais rapidos ou mais lentos

  int distDir1, distDir2, distEsq1, distEsq2;

  movCurvaDireita(veloc);
  delay(tempo); //tempo de movimentacao do robo para a direita
  parar(); //aguardar para fazer medicao da distancia para a direita
  distDir1 = sensor1();
  distDir2 = sensor2();
  delay(100);
  enviaString();

  movCurvaEsquerda(veloc);
  delay(tempo * 1.65); //tempo de movimentacao do robo para a esquerda, sendo o dobro do tempo da direita.
  //1x o tempo para poder retornar ao centro e outro tempo para poder girar para a esquerda
  parar(); //aguardar para fazer medicao da distancia para a esquerda
  distEsq1 = sensor1();
  distEsq2 = sensor2();
  delay(100);
  enviaString();

  if ((distDir1 + distEsq1) >= (distDir2 + distEsq2)) // direita > esquerda
  { // verifica se a distancia lida para a direita e maior que a da esquerda
    movCurvaDireita(veloc);
    delay(tempo * 1.65); //tempo de movimentacao do robo para girar para a direita
    parar();
    // retorna caminho escolhido: direita
  }
  else
  { // caso a distancia lida para a direita seja menor que a da esquerda
    parar();
    // retorna caminho escolhido: esquerda
  }
}

void limpaSerial()
{
  Serial.flush();
}
