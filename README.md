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
- Os operandos foram customizados com as parcelas do expoente e da mantissa com o seguinte cálculo:

### Primeiro: 
- Os operandos foram divididos da seguinte forma:

| **Sinal(+ ou -)** |  **Expoente**   |   **Mantissa**   |   
|-------------------|-----------------|------------------|
|         1         |        X        |         Y        | 

### Segundo:

- Para determinar o x
