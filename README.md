# TCC2_2021
Repositório de códigos e programas para o TCC2 de Marcos e Débora

O trabalho consiste em 1 carro robótico com 2 sensores ultrassônicos na frente, que medirão a distância de obstáculos à sua frente, e 1 carro virtual dentro do ambiente do CoppeliaSim, que deverá repetir os movimentos do carro físico. Os 2 se comunicam através de leitura e escrita Serial do Arduino.
Para isso, o código em Arduino possui 2 modos, automático e manual.
No manual ele receberá direções a partir do teclado (W,A,S,D) pressionadas dentro da simulação do CoppeliaSim e deve, a todo momento, fazer as leituras de distância dos sensores.
No automático ele deverá seguir em frente até se aproximar de um obstáculo, onde deverá girar para esquerda e para a direita, e seguir a direção da menor distância lida, desviando do obstáculo.

Dentro do CoppeliaSim o código que controla a cena irá ter uma janela com alguns controles do carro robótico, que permite alterar velocidade, tempo para manobras, ativar modo automático e sincronizar os dados da simulação para o Arduino.
Outra janela irá mostrar os valores que estão sendo lidos pelos sensores e que são enviados do Arduino para a simulação.
Com isso, o carro deve se movimentar dentro da simulação, o mais próximo do que ele se movimentaria no real.

Há o código Arduino (.ino) e o arquivo de edição da simulação (.ttt)
