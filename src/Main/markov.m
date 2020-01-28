caso = input(' nome do arquivo de dados (sem extensão):   ', 's');

if ~exist(caso)
  disp(' ')
  disp('   ********************************')
  disp('   *     ARQUIVO INEXISTENTE!     *')
  disp('   ********************************')
  disp(' ')
  return;
end

   format short;
   format compact;

disp(' ')
disp('   Iteração   Max_Desbalanço       miv          ||dx||')
disp(' ========================================================')

   eval(caso);
   
% O código permite ao usuário escolher a alternativa, e assim calcular os
% índices e os custos relacionados
% Definir Alternativa
alternativa = input('Alternativa:');
 
% Definir Tolerância 
tol = input('Tolerânica de confiabilidade(%):');
 

% Constantes

horasano=8760;
casos=7;
t=[3 5 7 9 11 13 15]; % posições MTTR transitorio
p=[2 4 6 8 10 12 14]; % posições MTTR permanente
trele=[0 0.33/3600 0.33/3600 0.33/3600 0.33/3600 0.33/3600 0.33/3600]; %tempos mortos
conversao=1000; % Conversão kwh/Mwh
lambdaP = 0.5; %falha permanente
lambdaT = 4.0 ;%falha transitoria
lambda = 4.5/8670 ; %saida taxa de falha por ano (saida/horas)
simulation = 5000; %numero de anos para laço da simulação
tfm=3/3600; % Tempo falhas momentaneas
% Inicializando Variaveis
amostra =0;
bheta = zeros(7,1);

% Semente para as variaveis aleatórias
 rng(1); 

for i=1:casos
for a=1:p
for b=1:t
 switch alternativa 
     case (i)
 Perm = tempos(:, a); % MTTR permanente
 Trans = tempos(:, b); % MTTRtransitório
 tmorto = trele(i); % tempo morto rele em horas
   end
end
end
end
 
 
% Configurações dos condutores
if alternativa ~= 7  % Alternativas exceto o 7
    distancias(16,:) =[]; %Retirar a linha de dados do componente 16(trecho novo alternativa 7)
end

 up=1;
 down=0;
 
 PA = distancias(:, 8)./conversao; % P fase A MW
 PB = distancias(:, 9)./conversao; % P fase B MW
 PC = distancias(:, 10)./conversao; % P fase C MW
 P = PA + PB + PC; % Ptotal de cada componente 

 compri = distancias(:, 4); %comprimentp de cada trecho
 NumCA = distancias(:, 5);
 NumCB = distancias(:, 6);
 NumCC = distancias(:, 7);
 NumC = NumCA + NumCB + NumCC; %numero de consumidores final de cada componente (trecho)
 
consumidores = NumC(1); % numero total de consumidores
 
 miP = 1./Perm;  %MTTR permanente
% miT = (1./trans)/3600;  %valores markov transitorio restabeleceimetno de H para S
 
 if alternativa == 1
     miT = (1./Trans);  % MTTR transitorio (horas)
 else
     miT = (1./(Trans/3600));  % MTTR transitorio (horas)
 end
 
%%  ------------- Inicio do Loop - Simulação ---------------------  %%
  for ano = 1:simulation
 

  FlhP = zeros(length(distancias),1); %vetor falha permanente
  FlhT = zeros(length(distancias),1); %vetor falha transitória
  FlhM = zeros(length(distancias),1); %vetor falha momentanea

  T_FlhP = zeros(length(distancias),1); %vetor tempo permanente
  T_FlhT = zeros(length(distancias),1); %vetor tempo transitório
 
 %inicializa variaveis
  estado(1:length(distancias)) = up ; 
  iter = 0;
  contP = 0;
  contT = 0;
  cont = 0;
  contT = 0;
  contM=0;

  %Variaveis teste para os índices de Disponibilidade
  ENS = 0; %energia não suprinda inicial = 0
  NumfalhaC = 0; % numero de falhas por consumidor
  NumtempoC = 0; %variavel para tempo de consumidor sem energia
  NumfalhaC_t = 0; %varaivel para falha transitória
  NumfalhaC_m=0;

% Inicialização 
 for i=1:length(distancias)       % inicializa tempo em UP para todos componentes
   tup(i) = (-1/(lambda*compri(i)))*log(rand); %horas
   estado(i) = 1; %todos componentes up
  end  
 
 comp = find(tup == min(tup)); %componente com menor tempo 
 time = tup; %tempo inicial com tUP  para vetor tempo

  tol=0;
 
%% ----------------- Monte Carlo - Mapa de Estados--------------------- %%
   
  while (tol < 1 )
   
   comp = find(time == min(time));  %seleciona o novo componente com o menor tempo

% Mapa de Estados
% Quando ocorre uma transição de UP para DOWN, estado do componente muda para 0.
% Quando ocorre uma transição de DOWN para UP, estado do componente muda para 1.

      if estado(comp) == 1      
          estado(comp) = 0;       %transitou para 0
          contT=contT+1;
         
      elseif estado(comp) == 0
          estado(comp) =1;         %transitou para 1
         
      end

      if estado(comp) == 1; % Transitou de DOWN e foi para UP.  
         tup = (-1/(lambda*compri(comp)))*log(rand); % tempo UP do componente.
         time(comp) = time(comp) + tup; %Acrescenta o tempo UP no tempo do componente.  
         
      elseif estado(comp) == 0 ; %Transita de UP para DOWN.
               
      U = rand; %Sorteio para verificar tipo da falha
             if U < 0.111 ;   %FALHA PERMANENTE
                tdown = (-1/miP(comp))*log(rand); %Calcula tempo em DOWN do componente.
                         
                contP = contP + 1; % Contador falhas Permanentes
                 
                FlhP(comp) = FlhP(comp)+1; %Contabiliza nº de falhas Permanentes
                T_FlhP(comp) = T_FlhP(comp) + tdown; %Armazena o tempo em DOWN da falha  Permanente (horas).
               
%%----------------------Alternativas para Planejamento do Alimentador - Falha Permanente----------------------%     
         
                     if (alternativa == 1 | alternativa == 2) % alternativa 1 e alternativa 2, atuação apenas do disjuntor geral.
                             
                             if alternativa == 2 %alternativa 2 entra o relé
                             tdown = tdown - tmorto; %Subtrair o tempo morto do relé (alternativa 1, tmorto =0).                
                             end
                             
                     ENS = ENS + tdown*P(1); %ENS  para toda potencia do sistema.
                     NumfalhaC = NumfalhaC + NumC(1); % numero de ocorrencia X nº de consumidores
                    NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos
                             
                     end  

%% --------------------------- Alternativa 3 --------------------------- %
                    if alternativa == 3 % alternativa 3 - ramos com fusível e religador para o tronco.
                      tdown = tdown - tmorto;

  % disjuntor/religador 
 if (comp == 1 | comp == 2 | comp == 9 | comp == 3 | comp == 4 | comp == 5);                    
 NumfalhaC = NumfalhaC + NumC(1); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos
ENS = ENS + tdown*(P(1)); % age disj/religador do tronco alimentador

 % Chave 1
 elseif (comp == 6 | comp == 7); % falha trecho 3-10 ou 3-4
 ENS = ENS + tdown*(P(6)); % age Chave 1, trecho 2-8 e 7-9 OFF.
 NumfalhaC = NumfalhaC + NumC(6); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(6); %tempo de falha X nº de consumidores atingidos

 % Chave 2
 elseif (comp == 10 | comp == 11); % falha trecho 4-11 ou 11-12         
  ENS = ENS + tdown*(P(10)); % age Chave 2, trecho 4-12 e 11-13 OFF
NumfalhaC = NumfalhaC + NumC(10); % numero de ocorrencia X nº de consumidores                      
 NumtempoC =NumtempoC + tdown * NumC(10); %tempo de falha X nº de consumidores atingidos

 % Chave 3
 elseif (comp == 13 | comp == 14); % falha trecho 5-14 ou 14-15
ENS = ENS + tdown*(P(13)); % age Chave 3, trecho 5-14 e 14-15 OFF
NumfalhaC = NumfalhaC + NumC(13); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(13); %tempo de falha X nº de consumidores atingidos

 % Chave 4    
elseif (comp == 8)% falha trecho 7-9
ENS = ENS + tdown*(P(8)); % age Chave 4, trecho 7-9 OFF
NumfalhaC = NumfalhaC + NumC(8); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(8); %tempo de falha X nº de consumidores atingidos

 % Chave 5     
 elseif (comp == 12)% falha trecho 11-13
ENS = ENS + tdown*(P(12)); % age Chave 5, trecho 11-13 OFF
NumfalhaC = NumfalhaC + NumC(12); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(12); %tempo de falha X nº de consumidores atingidos
                                   
% Chave 6      
 elseif (comp == 15)% falha trecho 14-16
 ENS = ENS + tdown*(P(15)); % age Chave 6, trecho 14-16 OFF
 NumfalhaC = NumfalhaC + NumC(15); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(15); %tempo de falha X nº de consumidores atingidos
                    end
                    end 

%% ---------------------------------- Alternativa 4 ------------------------ %

                    if alternativa == 4 %alternativa 4 - Religador no tronco, novo Chave 7 para o trecho 3-10
                       tdown = tdown - tmorto;
                    
 % disjuntor/religador 
if (comp == 1 | comp == 2 | comp == 3 | comp == 4 | comp == 5)
ENS = ENS + tdown*(P(1)); % age disj/religador do tronco alimentador
NumfalhaC = NumfalhaC + NumC(1); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos
                   
 % Chave 1
elseif (comp == 6 | comp == 7) % falha trecho 3-10 ou 3-4
ENS = ENS + tdown*(P(6)); % age Chave 1, trecho 2-8 e 7-9 OFF.
NumfalhaC = NumfalhaC + NumC(6); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(6); %tempo de falha X nº de consumidores atingidos
                          
% Chave 2 
 elseif (comp == 10 | comp == 11); % falha trecho 4-11 ou 11-12
ENS = ENS + tdown*(P(10)) ;% age Chave 2, trecho 4-12 e 11-13 OFF
NumfalhaC = NumfalhaC + NumC(10); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(10); %tempo de falha X nº de consumidores atingidos
                             
% Chave 3 
elseif (comp == 13 | comp == 14) %ocorre falha trecho 5-14 ou 14-15
ENS = ENS + tdown*(P(13)); % age Chave 3, trecho 5-14 e 14-15 OFF
NumfalhaC = NumfalhaC + NumC(13); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(13); %tempo de falha X nº de consumidores atingidos
                              
 % Chave 4      
 elseif (comp == 8)%ocorre falha trecho 7-9
ENS = ENS + tdown*(P(8)); % age Chave 4, trecho 7-9 OFF
NumfalhaC = NumfalhaC + NumC(8); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(8); %tempo de falha X nº de consumidores atingidos
                                  
 % Chave 5    
elseif (comp == 12)%ocorre falha trecho 11-13
ENS = ENS + tdown*(P(12)); % age Chave 5, trecho 11-13 OFF
NumfalhaC = NumfalhaC + NumC(12); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(12); %tempo de falha X nº de consumidores atingidos
                                    
 % Chave 6     
 elseif (comp == 15)%ocorre falha trecho 14-16
 ENS = ENS + tdown*(P(15)); % age Chave 6, trecho 14-16 OFF
 NumfalhaC = NumfalhaC + NumC(15); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(15); %tempo de falha X nº de consumidores atingidos

  % Chave 7    
 elseif (comp == 9)%ocorre falha trecho 3-10
 ENS = ENS + tdown*(P(9)); % age Chave 9, trecho 14-16 OFF
 NumfalhaC = NumfalhaC + NumC(9); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(9); %tempo de falha X nº de consumidores atingidos
                    end                      
                    end 

%% ---------------------------- Alternativa 5 --------------------------- %
                    if alternativa == 5
%  Religador em parte do tronco, novo Chave 8 para o trecho 3-10
                        tdown = tdown - tmorto;

 % disjuntor/religador 
if (comp == 1 | comp == 2)                       
ENS = ENS + tdown*(P(1)); % age disj/religador do tronco alimentador
NumfalhaC = NumfalhaC + NumC(1); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos

  % Chave 1 
elseif (comp == 6 | comp == 7) % falha trecho 3-10 ou 3-4
ENS = ENS + tdown*(P(6)); % age Chave 1, trecho 2-8 e 7-9 OFF.
NumfalhaC = NumfalhaC + NumC(6); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(6); %tempo de falha X nº de consumidores atingidos

  % Chave 2 
 elseif (comp == 10 | comp == 11) % falha trecho 4-11 ou 11-12
 ENS = ENS + tdown*(P(10)); % age Chave 2, trecho 4-12 e 11-13 OFF
 NumfalhaC = NumfalhaC + NumC(10); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(10); %tempo de falha X nº de consumidores atingidos


 % Chave 3 
 elseif (comp == 13 | comp == 14) % falha trecho 5-14 ou 14-15
 ENS = ENS + tdown*(P(13)); % age Chave 3, trecho 5-14 e 14-15 OFF
NumfalhaC = NumfalhaC + NumC(13); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(13); %tempo de falha X nº de consumidores atingidos

  % Chave 4      
 elseif (comp == 8)% falha trecho 7-9
 ENS = ENS + tdown*(P(8)); % age Chave 4, trecho 7-9 OFF
 NumfalhaC = NumfalhaC + NumC(8); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(8); %tempo de falha X nº de consumidores atingidos

% Chave 5      
 elseif (comp == 12)% falha trecho 11-13
 ENS = ENS + tdown*(P(12)); % age Chave 5, trecho 11-13 OFF
 NumfalhaC = NumfalhaC + NumC(12); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(12); %tempo de falha X nº de consumidores atingidos

  % Chave 6      
 elseif (comp == 15)% falha trecho 14-16
 ENS = ENS + tdown*(P(15)); %  Chave 6, trecho 14-16 OFF
  NumfalhaC = NumfalhaC + NumC(15); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(15); %tempo de falha X nº de consumidores atingidos

 % Chave 7      
  elseif (comp == 9)% falha trecho 3-10
  ENS = ENS + tdown*(P(9)); % age Chave 9, trecho 14-16 OFF
  NumfalhaC = NumfalhaC + NumC(9); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(9); %tempo de falha X nº de consumidores atingidos

 % Chave 8      
  elseif (comp == 3 | comp == 4 | comp == 5)% falha trecho 3-10
 ENS = ENS + tdown*(P(3)); % age Chave 9, trecho 14-16 OFF
 NumfalhaC = NumfalhaC + NumC(3); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(3); %tempo de falha X nº de consumidores atingidos
                    end                       
                    end 

%% ----------------------------------- Alternativa 6 ------------------------%

if alternativa == 6 % alternativa 6 - Religador 2 no ponto 3 para trecho 3-6
tdown = tdown - tmorto;

% disjuntor/religador 
 if (comp == 1 | comp == 2)  
ENS = ENS + tdown*(P(1)); % age disj/religador do tronco alimentador
NumfalhaC = NumfalhaC + NumC(1); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos

 % Chave 1 
  elseif (comp == 6 | comp == 7) % falha trecho 3-10 ou 3-4
  ENS = ENS + tdown*(P(6)); % age Chave 1, trecho 2-8 e 7-9 OFF.
  NumfalhaC = NumfalhaC + NumC(6); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(6); %tempo de falha X nº de consumidores atingidos

  % Chave 2
 elseif (comp == 10 | comp == 11) % falha trecho 4-11 ou 11-12
  ENS = ENS + tdown*(P(10)); % age Chave 2, trecho 4-12 e 11-13 OFF
  NumfalhaC = NumfalhaC + NumC(10); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(10); %tempo de falha X nº de consumidores atingidos

 % Chave 3 
  elseif (comp == 13 | comp == 14) %ocorre falha trecho 5-14 ou 14-15
  ENS = ENS + tdown*(P(13)); % age Chave 3, trecho 5-14 e 14-15 OFF
  NumfalhaC = NumfalhaC + NumC(13); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(13); %tempo de falha X nº de consumidores atingidos

 % Chave 4       
 elseif (comp == 8)% falha trecho 7-9
  ENS = ENS + tdown*(P(8)); % age Chave 4, trecho 7-9 OFF
  NumfalhaC = NumfalhaC + NumC(8); % numero de ocorrencia X nº de consumidores
  NumtempoC = NumtempoC + tdown * NumC(8); %tempo de falha X nº de consumidores atingidos
                              
 % Chave 5     
  elseif (comp == 12)% falha trecho 11-13
  ENS = ENS + tdown*(P(12)); % age Chave 5, trecho 11-13 OFF
  NumfalhaC = NumfalhaC + NumC(12); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(12); %tempo de falha X nº de consumidores atingidos

                                    
 % Chave 6      
  elseif (comp == 15)% falha trecho 14-16
  ENS = ENS + tdown*(P(15)); % age Chave 6, trecho 14-16 OFF
  NumfalhaC = NumfalhaC + NumC(15); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(15); %tempo de falha X nº de consumidores atingidos

                                      
 % Chave 7      
elseif (comp == 9)% falha trecho 3-10
ENS = ENS + tdown*(P(9)); % age Chave 9, trecho 14-16 OFF
NumfalhaC = NumfalhaC + NumC(9); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(9); %tempo de falha X nº de consumidores atingidos

                                          
 % religador 2      
  elseif (comp == 3 | comp == 4 | comp == 5)% falha trecho 3-6 
ENS = ENS + tdown*(P(3)); % age religador 2, para trecho 3-6
NumfalhaC = NumfalhaC + NumC(3); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(3); %tempo de falha X nº de consumidores atingidos
                    end                    
                    end 
 
                   
  %% ------------------------------ alternativa 7 -----------------------------%                 

 if alternativa == 7 % alternativa 7 - Religador 2 no ponto 3 para trecho 3-6 e linha 17 para suporte
 tdown = tdown - tmorto;

                      
 % disjuntor/religador  
if (comp == 1 | comp == 2)   
 ENS = ENS + tdown*((P(1)-P(9))); % age disj/religador do tronco alimentador, porem trecho 1-7 age!
 estado(16)=1; %trecho 1-17 entra!
 NumfalhaC = NumfalhaC + (NumC(1)-NumC(9)); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * (NumC(1)-NumC(9)); %tempo de falha X nº de consumidores atingidos

                    
% Chave 1 
elseif (comp == 6 | comp == 7) % falha trecho 3-10 ou 3-4
ENS = ENS + tdown*(P(6)); % age Chave 1, trecho 2-8 e 7-9 OFF.
 NumfalhaC = NumfalhaC + NumC(6); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(6); %tempo de falha X nº de consumidores atingidos

                         
 % Chave 2 
  elseif (comp == 10 | comp == 11) % falha trecho 4-11 ou 11-12
  ENS = ENS + tdown*(P(10)); % age Chave 2, trecho 4-12 e 11-13 OFF
  NumfalhaC = NumfalhaC + NumC(10); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(10); %tempo de falha X nº de consumidores atingidos

                           
  % Chave 3 
 elseif (comp == 13 | comp == 14) % falha trecho 5-14 ou 14-15
 ENS = ENS + tdown*(P(13)); % age Chave 3, trecho 5-14 e 14-15 OFF
 NumfalhaC = NumfalhaC + NumC(13); % numero de ocorrencia X nº de consumidores
  NumtempoC =NumtempoC + tdown * NumC(13); %tempo de falha X nº de consumidores atingidos

                               
% Chave 4      
  elseif (comp == 8)% falha trecho 7-9
  ENS = ENS + tdown*(P(8)); % age Chave 4, trecho 7-9 OFF
  NumfalhaC = NumfalhaC + NumC(8); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(8); %tempo de falha X nº de consumidores atingidos

                                
 % Chave 5      
 elseif (comp == 12)% falha trecho 11-13
 ENS = ENS + tdown*(P(12)); % age Chave 5, trecho 11-13 OFF
 NumfalhaC = NumfalhaC + NumC(12); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(12); %tempo de falha X nº de consumidores atingidos

                                     
% Chave 6    
 elseif (comp == 15)% falha trecho 14-16
 ENS = ENS + tdown*(P(15)); % age Chave 6, trecho 14-16 OFF
 NumfalhaC = NumfalhaC + NumC(15); % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown * NumC(15); %tempo de falha X nº de consumidores atingidos

                                       
% Chave 7      
elseif (comp == 9)% falha trecho 3-10, porem linha 1-17 entra
estado(16) = 1; %linha 1-17 age
ENS = ENS + tdown*0; % age Chave 9, linha 1-17 abastece carga
NumfalhaC = NumfalhaC + 0; % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown *0 ; %tempo de falha X nº de consumidores atingidos
                                         
                                        
 % religador 2     
 elseif (comp == 3 | comp == 4 | comp == 5)% falha trecho 3-6
ENS = ENS + tdown*(P(3)); % age religador 2, para trecho 3-6
 NumfalhaC = NumfalhaC + NumC(3); % numero de ocorrencia X nº de consumidores
 NumtempoC =NumtempoC + tdown * NumC(3); %tempo de falha X nº de consumidores atingidos

                                        
 % disjuntor 1-17
 elseif (comp == 16)% falha trecho 1-17
  if estado(9) == 0 %se componente 9 (3-10) estava off
 ENS = ENS + tdown*P(9); % componente 9 OFF
NumfalhaC = NumfalhaC + NumC(9); % nº de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown *NumC(9) ; %tempo de falha X nº de consumidores atingidos
                                       
 else % se o componente 9 ja estava on a linha não estava sendo usada  
 ENS = ENS + tdown*0; % comp 9 não é contabilizado
 NumfalhaC = NumfalhaC + 0; % numero de ocorrencia X nº de consumidores
NumtempoC =NumtempoC + tdown *0 ; %tempo de falha X nº de consumidores atingidos
                        end 
                    end                    
                    end           
             time(comp) = time(comp) + tdown; %Incrementa o tempo em DOWN no tempo do componente.
         
             % FALHA TRANSITÓRIA

% Tempo em down - Transitorio dos componentes 
            else 
             tdown = (-1/miT(comp))*log(rand); 
             contT = contT + 1; % Contador para falhas Transitorias. 
             FlhT(comp) = FlhT(comp) + 1; %Contabiliza falhas Transitorias.
             

             % Desconta o tempo morto do relé para periodo transitório.
             T_FlhT(comp) = T_FlhT(comp) + tdown; %Armazena o tempo em DOWN da falha  Transitória (horas).
             
             if alternativa == 1 % só disjuntor
             ENS = ENS + tdown*(P(1)); %ENS para a alternativa 1, onde toda falta transitória é permanente
             NumfalhaC = NumfalhaC + NumC(1); 
            
            NumtempoC =NumtempoC + tdown * NumC(1); %tempo de falha X nº de consumidores atingidos
             
             time(comp) = time(comp) + tdown;    
                 
             else % para todas alternativas exceto a 1º
             tdown = tdown - tmorto;   % Desconta o tempo morto do relé para periodo transitório.

             time(comp) = time(comp) + tdown; 
             
                    if alternativa == 6 %nesta alternativa ocorre a instalação do 2º religador no tronco
                        if (comp==1|comp== 2|comp==6|comp==7|comp==8|comp==9) %falha na região do 1ºreligador 
                        NumfalhaC_t = NumfalhaC_t +  NumC(1); 
                          NumfalhaC_m = NumfalhaC_m +  NumC(1);                     
                        else
                            NumfalhaC_t = NumfalhaC_t +  NumC(3); %consumidores atingidos pelo 2º religador
                            NumfalhaC_m =  NumfalhaC_m +  NumC(3); %consumidores atingidos pelo 2º religador
                        end
                       
                    else
                        % para as outras alternativas
                         NumfalhaC_t = NumfalhaC_t +  NumC(1); %todos consumidores atingidos pelo 1º religador 
                         NumfalhaC_m = NumfalhaC_m +  NumC(1);
                    end                   
             end 
            end         
   end   

% Loop para todos os estados atingirem 1 ano
if min(time)>= horasano
    break
end

%Contador de Iterações
iter = iter +1 ; 
end 

amostra = amostra + 1;

%% ----------  Indices de Disponibilidade --------------- %%

% SAIFI
MSAIFI(ano) = NumfalhaC / consumidores; 

%CAIFI
if alternativa == 1  
MCAIFI(ano) = NumfalhaC / consumidores; % Na alternativa 1 todos consumidores experimentam pelo menos 1 falha
else
MCAIFI(ano) = NumfalhaC / max(NumC(find(FlhP)));
end

%SAIDI
MSAIDI(ano) = NumtempoC /consumidores;

%CTAIDI
MCTAIDI(ano) = NumtempoC / max(NumC(find(FlhP)));

%CAIDI
 MCAIDI(ano) = MSAIDI(ano)/MSAIFI(ano);

%ENS
MENS(ano) = ENS; %recebe ENS de cada ano

%AENS
MAENS = (MENS(ano) / consumidores)*1000;



%% ------------------------- Critério de parada ----------------------- %%
 if ano>5
bheta(1) = sqrt(var(MSAIFI)/amostra)/((1/amostra)*sum(MSAIFI));
bheta(2) = sqrt(var(MCAIFI)/amostra)/((1/amostra)*sum(MCAIFI));
bheta(3) = sqrt(var(MSAIDI)/amostra)/((1/amostra)*sum(MSAIDI));
bheta(4) = sqrt(var(MCTAIDI)/amostra)/((1/amostra)*sum(MCTAIDI));
bheta(5) = sqrt(var(MCAIDI)/amostra)/((1/amostra)*sum(MCAIDI));
bheta(6) = sqrt(var(MENS)/amostra)/((1/amostra)*sum(MENS));
bheta(7) = sqrt(var(MAENS)/amostra)/((1/amostra)*sum(MAENS));
max(bheta);
    if max(bheta)<(tol/100)
          break
    end
 end

 
  end 
 
   
 % ---------------- Resultado Indíces de Disponibilidade ------------------ %
 
SAIFI = mean(MSAIFI);
 
CAIFI = mean(MCAIFI);

SAIDI = mean(MSAIDI);

CTAIDI = mean(MCTAIDI);

CAIDI = mean(MCAIDI);

ASAI = 1- (SAIDI/horasano);

ENS = mean(MENS);

AENS = MAENS;
 

fprintf('\n')
fprintf('                                 Índices de Disponibilidade para Alternativa %i \n',                         alternativa);
disp('====================================================================================================================');
fprintf('                                       SAIFI (occ/y): %.2f \n',                                                                          SAIFI);
fprintf('                                       CAIFI (occ/y): %.2f \n',                                                                          CAIFI);
fprintf('                                       SAIDI (h/occ): %.2f \n',                                                                          SAIDI);
fprintf('                                       CTAIDI (h/y): %.2f \n',                                                                          CTAIDI);
fprintf('                                       CAIDI (h/occ): %.2f \n',                                                                          CAIDI);
fprintf('                                       ASAI: %.3f \n',                                                                                    ASAI);
fprintf('                                       ENS(MWh): %.2f \n',                                                                                 ENS);
fprintf('                                       AENS: %.2f \n',                                                                                    AENS);
disp('====================================================================================================================');
fprintf(' Coeficiente de Variação: %.2f \n ', tol);
fprintf('Convergência: %i anos \n',                                                                                                                 ano);
fprintf('\n')


fprintf('\n')
fprintf('                                 Custos para Alternativa %i \n',                         alternativa);
        
%% Custos de Implementação

custoM=[
100; % Cubículo (Disjuntor, relés secundários, sobrecorrent de fase e neutro e medição de kWh, Amp e KVArh)
120; % Idem ao anterior + relé de religamento 
16*3; % Quilômetro do alimentador 556,500
13*3; % Quilômetro do alimentador 4/0
10*2; % Quilômetro do alimentador 1/0 
8; % Quilômetro do alimentador #2 
6; % Quilômetro do alimentador #4 
1; % Conjunto chave fusível
1; % Conjunto chave faca 
30]; % Religador instalado 


% CustosM tem que ser multiplicado pelo número de fases da linha 
matalt1=[1 ; 0 ; 5 ; 20 ; 20 ; 5 ; 3 ; 0 ; 0 ; 0];
matalt2=[0 ; 1 ; 5 ; 20 ; 20 ; 5 ; 3 ; 0 ; 0 ; 1];
matalt3=[0 ; 1 ; 5 ; 20 ; 20 ; 5 ; 3 ; 6 ; 0 ; 1];
matalt4=[0 ; 1 ; 5 ; 20 ; 20 ; 5 ; 3 ; 7 ; 0 ; 1];
matalt5=[0 ; 1 ; 5 ; 20 ; 20 ; 5 ; 3 ; 8 ; 0 ; 1];
matalt6=[0 ; 1 ; 5 ; 20 ; 20 ; 5 ; 3 ; 8 ; 0 ; 2];
matalt7=[0 ; 2 ; 5+sqrt(5^2+5^2) ; 20 ; 20 ; 5 ; 3 ; 7 ; 3 ; 2];
matalt=[matalt1 matalt2 matalt3 matalt4 matalt5 matalt6 matalt7];
% Custos de Implementação
Cimp=sum(1000*custoM.*matalt(:,alternativa));
fprintf('\n Custos de Implementação: %i ', Cimp);



%% ------------------ Custos Variáveis --------------------- %%


%% Puxar dados do Simulador:
% 1 - ENS
% 2 - número de falhas transitórias
% 3 - número de falhas permanentes


% Constantes
mip=tempos(:,p);
mit=tempos(:,t);
kwh=0.3315;
cft=100;
cfp=350;
       
% Custos de Energia Não Suprida %
cens=kwh*ENS;

% Custo de Reparo Transitório ( somente haverá para Alternativa 1)
if alternativa==1
crt=sum((cft.*Trans.*NumfalhaC_t))/amostra;
else
crt=0;
end

% Custo de Reparo Permanente
crp=sum((cfp*sum(Perm)*NumfalhaC))/amostra;

format long

% Custo Variável Total
CT=crp+crt+cens;
fprintf('\n Custo Variável Total: %i ', CT);


% Custo Anual de Implementação %%

%taxa de juros
tx=0.06;
t=20;
R=Cimp*(((1+tx)^t)*tx)/(((1+tx)^t)-1);
fprintf('\n Custo Anual de Implementação: %i ', R);

% Valor de recuperação do capital - custos variáveis totais

CustosT=R+CT;

fprintf('\n Custos Líquidos Anuais: %i ', CustosT);

% Payback

% Será calculada à partir da alternativa 02 com relação as alternativas com
% maior Custos Líquidos Totais

for i=1:alternativa-1
if alternativa==2

DF21=Cimp - 1578000;
DL21=3.545146e+06 - CustosT;
Payback21=DF21/DL21;

Payback=[Payback21];
fprintf('\n Payback em Anos da Alternativa 2 em Relação a Alternativa %i: %i ',  i, Payback(i));
end

if alternativa==3

DF31=Cimp - 1578000;
DL31=3.545146e+06 - CustosT;
Payback31=DF31/DL31;

DF32 = Cimp - 1628000;
DL32 = 6.006890e+05-CustosT;
Payback32 = DF32/DL32;

Payback=[Payback31 Payback32];
fprintf('\n Payback em Anos da Alternativa 3 em Relação a Alternativa %i: %i ',  i, Payback(i));
end

if alternativa==4

DF41=Cimp  - 1578000;
DL41=3.545146e+06 - CustosT;
Payback41=DF41/DL41;

DF42 = Cimp - 1628000;
DL42 = 6.006890e+05- CustosT;
Payback42 = DF42/DL42;

DF43 = Cimp - 1634000;
DL43 = 4.077828e+05 - CustosT;
Payback43 = DF43/DL43;

Payback=[Payback41 Payback42 Payback43];
fprintf('\n Payback em Anos da Alternativa 4 em Relação a Alternativa %i: %i ',  i, Payback(i));
end

if alternativa==5

DF51=Cimp - 1578000;
DL51=3.545146e+06 - CustosT ;
Payback51=DF51/DL51;

DF52 = Cimp - 1628000;
DL52 = 6.006890e+05 - CustosT;
Payback52 = DF52/DL52;

DF53 = Cimp - 1634000;
DL53 =  4.077828e+05 - CustosT;
Payback53 = DF53/DL53;

DF54 = Cimp - 1635000;
DL54 = 3.959568e+05 - CustosT;
Payback54 = DF54/DL54;

Payback=[Payback51 Payback52 Payback53 Payback54];
fprintf('\n Payback em Anos da Alternativa 5 em Relação a Alternativa %i: %i ',  i, Payback(i));
end

if alternativa==6

DF61=Cimp - 1578000;
DL61=3.545146e+06 - CustosT;
Payback61=DF61/DL61;

DF62 = Cimp - 1628000;
DL62 = 6.006890e+05 -  CustosT;
Payback62 = DF62/DL62;

DF63 = Cimp - 1634000;
DL63 =  4.077828e+05 - CustosT;
Payback63 = DF63/DL63;

DF64 = Cimp - 1635000;
DL64 = 3.959568e+05 - CustosT;
Payback64 = DF64/DL64;

DF65 = Cimp - 1636000;
DL65 =  2.549007e+05- CustosT;
Payback65 = DF65/DL65;

Payback=[Payback61 Payback62 Payback63 Payback64 Payback65];
fprintf('\n Payback em Anos da Alternativa 6 em Relação a Alternativa %i: %i ',  i, Payback(i));
end

if alternativa==7

DF71=Cimp - 1578000;
DL71=3.545146e+06 - CustosT;
Payback71=DF71/DL71;

DF72 = Cimp - 1628000;
DL72 = 6.006890e+05 -  CustosT;
Payback72 = DF72/DL72;

DF73 = Cimp - 1634000;
DL73 =  4.077828e+05 - CustosT;
Payback73 = DF73/DL73;

DF74 = Cimp - 1635000;
DL74 = 3.959568e+05 - CustosT;
Payback74 = DF74/DL74;

DF75 = Cimp - 1636000;
DL75 =  2.549007e+05- CustosT;
Payback75 = DF75/DL75;

DF76 = Cimp - 1666000;
DL76 =  2.575162e+05 - CustosT;
Payback76 = DF76/DL76;

Payback=[Payback71 Payback72 Payback73 Payback74 Payback75 Payback76];
fprintf('\n Payback em Anos da Alternativa 7 em Relação a Alternativa %i: %i ',  i, Payback(i));
end
end
