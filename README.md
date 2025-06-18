# FPU
Esse projeto tem como objetivo entender o papel do padrão IEEE-754 em projetos de hardware de unidades de ponto-flutuante (FPU's). O desafio foi formatar nossos próprios operandos de acordo com a nossa matrícula.

## Interface:

![alt text]({3D7B944B-E27B-4AC6-AD61-527C23A21FD7}.png)

|    **Sinal**   |   **Direção**   |               **Descrição**                |
|----------------|-----------------|--------------------------------------------|
|  `clock_100k`  |      Input      |   Clock de 100KHz                          | 
|  `reset`       |      Input      |   Reset assíncrono-baixo                   |
|  `op_a e op_b` |      Input      |   Operandos da soma/subtração              | 
|  `data_out`    |      Output     |   Resultado da Operação                    | 
|  `status_out`  |      Output     |   Informação do resultado no estilo one-hot| 

## Operandos op_a e op_b:
- Os operandos foram customizados com a nossa matrícula da seguinte forma:

### Primeiro: 
- Os operandos foram divididos da seguinte forma:

| **Sinal(+ ou -)** |  **Expoente**   |   **Mantissa**   |   
|-------------------|-----------------|------------------|
|        `1`        |       `X`       |       `Y`        | 

### Segundo:

- Para determinar o x foi utilizado o seguinte cálculo:

              | X = [8 (+/-) ∑b mod 4] |
  
- Onde ∑b representa a soma de todos os dígitos do número de matrícula (base 10) e mod 4 
representa o resto da divisão inteira por 4. O sinal + ou - é determinado pelo dígito 
verificador do número de matrícula: + se for ímpar, - se for par.

- E para determinar o Y foi utilizado o seguinte cálculo:

                        Y = 31 - X.
  


