# FPU
Esse projeto tem como objetivo entender o papel do padrão IEEE-754 em projetos de hardware de unidades de ponto-flutuante (FPU's). O desafio foi formatar nossos próprios operandos de acordo com a nossa matrícula.

## Interface:

![alt text]({3D7B944B-E27B-4AC6-AD61-527C23A21FD7}.png)

|    **Sinal**   |   **Direção**   |                 **Descrição**                |
|----------------|-----------------|----------------------------------------------|
|  `clock_100k`  |      Input      |   Clock de 100KHz                            | 
|  `reset`       |      Input      |   Reset assíncrono-baixo                     |
|  `op_a e op_b` |      Input      |   Operandos da soma/subtração                | 
|  `data_out`    |      Output     |   Resultado da Operação                      | 
|  `status_out`  |      Output     |   Informação do resultado no estilo one-hot  | 

## Operandos op_a e op_b:
- Os operandos foram customizados com a nossa matrícula da seguinte forma:

### Primeiro: 
- Os operandos foram divididos da seguinte forma:

| **Sinal(+ ou -)** |  **Expoente**   |   **Mantissa**   |   
|-------------------|-----------------|------------------|
|        `1`        |       `X`       |       `Y`        | 

### Segundo:

- Para determinar o x foi utilizado o seguinte cálculo:

               X = [8 (+/-) ∑b mod 4] 
  
- Onde ∑b representa a soma de todos os dígitos do número de matrícula (base 10) e mod 4 
representa o resto da divisão inteira por 4. O sinal + ou - é determinado pelo dígito 
verificador do número de matrícula: + se for ímpar, - se for par.

- E para determinar o Y foi utilizado o seguinte cálculo:

                        Y = 31 - X.

- Então, de acordo com a minha mátricula (24102913-1) foi calculado da seguinte forma:

      X = [8 + (2+4+1+0+2+9+1+3+1) mod 4] = [8 + 23 mod 4] = [8 + 3] = 11
      Y = [31 - 11] = 20
  
- Dessa forma meus operandos ficaram no seguinte formado:

| **Sinal(+ ou -)** |  **Expoente**   |   **Mantissa**   |   
|-------------------|-----------------|------------------|
|        `1`        |       `11`      |       `20`       | 

## Como funciona :

A FPU foi programada com uma máquina de estados que são :  DIVIDE, PRE_ADD, ADD, POS_ADD, NORMALIZER, OUTPUT_RESULT;

A máquina inicializa os sinais, os registradores e as flags (que serão usadas no `status_out`). Ela passa para o estado `DIVIDE`, onde ele recebe os operandos com os números padronizados e "desmancha" eles em sinal, expoente e mantissa. Após, vai para o estado `PRE_ADD` que verifica os expoentes, se os expoentes forem iguais, então, vai para o estado `ADD`, se não ele faz com que os operandos fiquem com o mesmo expoente "shiftando" o operando com o menor expoente. Depois, vai para o estado `ADD`, onde ocorre a soma/subtração que depende dos sinais, pois, se os sinais forem iguais ele soma diretamente as mantissas e mantém o sinal dos dois operandos, se não ele compara as mantissas para fazer subtração da maior mantissa pela menor mantissa, e o sinal do resultado será o da maior mantissa. Depois, vai para o estado `POS_ADD`para ajustar a mantissa e o sinal final, além de dizer se o operando final resulta em 0. O estado muda para o `NORMALIZER` que faz o papel de normalizar o resultado, "shiftando" de volta a diferença dos expoentes que teve de fazer para realizar a soma das mantissas no estado `PRE_ADD`, além de definir as flags de overflow, underflow, exatidão e zero. E finalmente, no estado `OUTPUT_RESULT`, é onde concatena o `sinal final`, o `expoente final` e a `mantissa final`, concatena as flags (respectivamente, [3] EXACT, [2] OVERFLOW, [1] UNDERFLOW, [0] INEXACT), se houve overflow a saída recebe infinito com sinal correto e se o resultado é zero a saída recebe zero.

## Descrição do espectro espectro numérico representável pela FPU de padrão customizado:

- Representação decimal:
  
![{649A1B34-5779-408B-A40D-D1446E8BBBD4}](https://github.com/user-attachments/assets/3e8d6d97-fe05-479f-bb74-292a14b93585)


- Representação binária:                          

![{4086F72E-BCBB-4E38-A1FF-282606A91EA1}](https://github.com/user-attachments/assets/8e39e370-c928-4db0-89a5-33236dfcb6b0)



## Como simular
Para simular a FPU , entre na pasta `TB/` e então utilize o comando `do sim.do` para simular. 

## Resultados da simulação:

![{2A114C3D-264E-4A7F-8E91-CC3463511EDA}](https://github.com/user-attachments/assets/1a989d57-b6eb-4bc4-a6a3-be712a9d41c2)


![{25D7111C-9C6B-4268-B3BD-44132D31A804}](https://github.com/user-attachments/assets/7e451caf-259e-45ae-8fa7-f4db53c46b8c)




