
create database nba;
create table temporadas(
id smallint,
nome_jogador varchar(255),
abreviacao_team varchar(255),
idade float,
altura float,
peso float,
universidade varchar(255),
pais varchar(255),
ano_draft smallint,
ronda_draft tinyint,
num_draft tinyint,
jogos tinyint,
pontos float,
ressaltos float,
assistencias float,
classificacao_liquida float,
percentual_ressaltos_ofensivos float,
percentual_ressaltos_defensivos float,
percentual_uso float,
percentual_arremesso_verdadeiro float,
percentual_assistencias float,
temporada varchar(255)
); 

/* 
Procedimento de Limpeza de Dados
Os seguintes problemas estão sendo tratados:
1. Remover espaços em branco no início e no fim de todas as colunas de texto/VARCHAR
2. As colunas ano_draft, ronda_draft e num_draft eram originalmente strings porque continham o valor "Undrafted".
   O plano é substituir todos os valores "Undrafted" por NULL e converter as colunas afetadas para o tipo INT
3. A coluna temporada veio no formato "1996-97"
   O plano é extrair a temporada inicial "1996" de acordo com as convenções da NBA e converter para INT
4. Modificar as colunas para refletir as mudanças nos tipos de dados
*/
-- Verificar os tipos de dados
 DESCRIBE temporadas;
 
SET SQL_SAFE_UPDATES = 0;

UPDATE temporadas
SET 
	nome_jogador = NULLIF(TRIM(nome_jogador), ""),
    abreviacao_team = NULLIF(TRIM(abreviacao_team), ""),
    universidade = NULLIF(TRIM(universidade), ""),
    pais = TRIM( pais),
	ano_draft = CAST(NULLIF(TRIM(ano_draft), "Undrafted") AS UNSIGNED),
    ronda_draft = CAST(NULLIF(TRIM(ronda_draft), "Undrafted") AS UNSIGNED),
    num_draft = CAST(NULLIF(TRIM(num_draft), "Undrafted") AS UNSIGNED),
    temporada = CAST(LEFT(TRIM(temporada), 4) AS UNSIGNED);
    
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE temporadas
MODIFY COLUMN ano_draft YEAR,
MODIFY COLUMN ronda_draft INT,
MODIFY COLUMN num_draft INT,
MODIFY COLUMN temporada YEAR;

-- Verificando as modificações feitas
DESCRIBE temporadas;


-- Verificando valores irrealistas
-- Criando uma tabela duplicada
DROP TABLE IF EXISTS temporadas_copia;
CREATE TABLE temporadas_copia AS (
	SELECT *
	FROM temporadas
);

-- Os dados agora estão prontos para análise

/* Perguntas a responder
Quais jogadores lideraram suas temporadas em pontuação, rebotes e criação de jogadas — e quão eficientes eles foram?

Como os jogadores de diferentes eras (anos 1990, 2000, 2010 e 2020) se comparam em tamanho, estilo e desempenho?

Quais equipes, posições ou tipos de jogadores produzem consistentemente os melhores desempenhos?

Com base nos dados, quem merece o prêmio de MVP — e como essa escolha se compara ao MVP oficial da NBA?
*/

-- Verificações preliminares --

-- Verificar duplicados
SELECT
	nome_jogador, count(*)
FROM
	temporadas
Group by nome_jogador, temporada, idade, abreviacao_team, universidade
HAVING count(*) > 1;

-- Nenhum registro duplicado foi encontrado.

-- Quantas linhas de dados existem?
SELECT 
	COUNT(id) AS num_registros
FROM
	temporadas;
-- Existem 10.422 registros no conjunto de dados

-- Quantos jogadores únicos existem no conjunto de dados?
SELECT 
	COUNT(DISTINCT nome_jogador) AS jogadores_unicos
FROM 
	temporadas;
-- Existem 1.757 jogadores únicos

-- Quantas equipes únicas existem nos dados
SELECT 
	COUNT(DISTINCT abreviacao_team) AS num_equipas
FROM 
	temporadas;
-- Existem 36 equipes únicas no conjunto de dados

-- Quantas temporadas da NBA estamos analisando?
SELECT 
	COUNT(DISTINCT temporada) AS temporada
FROM 
	temporadas;
-- Existem 27 temporadas da NBA no conjunto de dados, abrangendo de 1996 a 2022.

-- Quantos países estão representados na NBA?
SELECT 
	COUNT(DISTINCT pais) AS pais
FROM 
	temporadas;
-- Existem 66 países diferentes representados na NBA

-- Os 5 principais países
SELECT 
	pais, COUNT(pais) AS cinco_principais_paises
FROM 
	temporadas
GROUP BY 
	pais
ORDER BY pais DESC LIMIT 5;
-- Percentagem de cada pais
SELECT 
    pais,
    COUNT(*) AS quantidade,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM temporadas),
        2
    ) AS percentagem
FROM temporadas
GROUP BY pais
ORDER BY percentagem DESC;
-- A maioria dos jogadores da NBA, 83,9%, é dos EUA.

-- Quantas universidades produzem jogadores da NBA
SELECT 
	COUNT(DISTINCT universidade) AS qtd_universidade
FROM 
	temporadas;
-- 251 universidades produzem jogadores da NBA

-- Quais são as 10 universidades que mais produzem jogadores
SELECT 
	universidade, COUNT(universidade) AS qtd_universidade
FROM 
	temporadas
GROUP BY universidade
ORDER BY qtd_universidade DESC limit 10;
-- Descobriu-se que 1611 jogadores não vieram de nenhuma universidade. Kentucky, Duke e North Carolina
-- lideraram como as universidades que mais produziram jogadores da NBA

-- Verificando os valores máximos e mínimos de estatísticas como jogos disputados, pontos, rebotes, assistências e classificação liquida para possíveis outliers
SELECT 
	max(jogos), min(jogos)
FROM temporadas;
SELECT 
	max(pontos), min(pontos)
FROM temporadas;
SELECT 
	max(ressaltos), min(ressaltos)
FROM temporadas;
SELECT 
	max(assistencias), min(assistencias)
FROM temporadas;
SELECT 
	max(classificacao_liquida), min(classificacao_liquida)
FROM temporadas;
-- Parece que a classificação liquida possuem valores extremamente fora do padrão; máximo: 114.3, mínimo: -250
-- Isso precisa de investigação adicional, já que classificações liquidas normalmente variam de -30 a +30

-- Verificar os valores máximos e mínimos das estatísticas avançadas
SELECT 
	max(percentual_arremesso_verdadeiro), min(percentual_arremesso_verdadeiro)
FROM temporadas;
SELECT 
	max(percentual_assistencias), min(percentual_assistencias)
FROM temporadas;
SELECT 
	max(percentual_ressaltos_defensivos), min(percentual_ressaltos_defensivos)
FROM temporadas;
SELECT 
	max(percentual_ressaltos_ofensivos), min(percentual_ressaltos_ofensivos)
FROM temporadas;
-- As estatísticas avançadas em porcentagem variam entre 0 e 1
-- Exceto o percentual_arremesso_verdadeiro, que apresentou um máximo de 1,5, o que é impossível. Precisa de investigação e correção.

-- Verificando os outliers em classificacao_liquida
SELECT 'MAXIMO' AS tipo,
	nome_jogador
FROM temporadas
where classificacao_liquida = (SELECT MAX(classificacao_liquida) FROM temporadas)

UNION ALL

SELECT 'MINIMO' AS tipo,
	nome_jogador
FROM temporadas
where classificacao_liquida = (SELECT MIN(classificacao_liquida) FROM temporadas)
;

-- Verificando os outliers em arremesso_verdadeiro
SELECT 'MAXIMO' AS tipo,
	nome_jogador
FROM temporadas
where percentual_arremesso_verdadeiro = (SELECT MAX(percentual_arremesso_verdadeiro) FROM temporadas)

union all

SELECT 'MINIMO' AS tipo,
	nome_jogador
FROM temporadas
where percentual_arremesso_verdadeiro = (SELECT MIN(percentual_arremesso_verdadeiro) FROM temporadas)
;

/*
Tratamento de outliers
A estratégia é substituir os valores outliers pela média dos valores do jogador em outras temporadas.

1. Obter os jogadores com outliers
2. Obter a média de todos os jogadores com outliers, excluindo a temporada com o outlier
3. Atualizar os outliers com suas médias individuais.
   */

-- Etapa 1: Obter os jogadores com outliers
CREATE TEMPORARY TABLE outliers_jogadores AS
SELECT DISTINCT
	nome_jogador
FROM
	temporadas
WHERE
	percentual_arremesso_verdadeiro > 1.0 OR 
    classificacao_liquida > 30 OR 
    classificacao_liquida < -30;
-- Etapa 2: Obter a média de todos os jogadores com outliers excluindo a temporada com o outlier
CREATE TEMPORARY TABLE outliers_jogadores_media AS
SELECT
	temp.nome_jogador,
    AVG(CASE WHEN classificacao_liquida BETWEEN -30 AND 30 THEN classificacao_liquida END) AS media_classificacao_liquida,
    AVG(CASE WHEN percentual_arremesso_verdadeiro <= 1 THEN percentual_arremesso_verdadeiro END) AS media_arremesso_verdadeiro
FROM 
	temporadas AS temp
JOIN outliers_jogadores AS jco
	ON temp.nome_jogador = jco.nome_jogador
GROUP BY
	nome_jogador;
-- Etapa 3: Atualizar os outliers com suas médias individuais usando left_join
UPDATE temporadas temp
LEFT JOIN
	outliers_jogadores_media 
    ON temp.nome_jogador = outliers_jogadores_media.nome_jogador
SET
	temp.classificacao_liquida = 
		CASE WHEN temp.classificacao_liquida > 30 OR temp.classificacao_liquida < -30 THEN outliers_jogadores_media.media_classificacao_liquida
			ELSE temp.classificacao_liquida END,
    temp.percentual_arremesso_verdadeiro = 
		CASE WHEN temp.percentual_arremesso_verdadeiro > 1 THEN outliers_jogadores_media.media_arremesso_verdadeiro
        ELSE temp.percentual_arremesso_verdadeiro END;
-- Apgar TEMPORARY TABLE outliers_jogadores;
DROP TEMPORARY TABLE outliers_jogadores;
-- Apagar TEMPORARY TABLE outliers_jogadores_media;
DROP TEMPORARY TABLE outliers_jogadores_media;
-- Verificar se as alterações funcionaram
SELECT DISTINCT
	nome_jogador
FROM
	temporadas
WHERE
	percentual_arremesso_verdadeiro > 1.0 OR 
    classificacao_liquida > 30 OR 
    classificacao_liquida < -30;
-- Agora que os dados estão limpos e os outliers tratados
-- Estamos prontos para realizar as tarefas

/* 1. Análise de Desempenho dos Jogadores

```
Classificar jogadores em cada temporada por pontos, rebotes e assistências por jogo.

Comparar estatísticas de eficiência (Arremesso verdadeiro% vs uso%) — jogadores de alto volume sacrificam eficiência?

Identificar os jogadores que mais evoluíram entre temporadas (maior aumento em pontos/rebotes/assistências).
```

*/

-- Ranking por pontos
SELECT
	temporada,
	RANK() OVER (PARTITION BY temporada ORDER BY pontos DESC) AS pontos_por_temporada,
	nome_jogador,
    pontos   
FROM 
	temporadas;

-- Ranking por rebotes
SELECT
	temporada,
	RANK() OVER (PARTITION BY temporada ORDER BY ressaltos DESC) AS ressaltos_por_temporada,
	nome_jogador,
    ressaltos  
FROM 
	temporadas;

-- Ranking por assistências por jogo
SELECT
	temporada,
	RANK() OVER (PARTITION BY temporada ORDER BY assistencias DESC) AS assistencias_por_temporada,
	nome_jogador,
    assistencias   
FROM 
	temporadas;
-- Comparar estatísticas de eficiência (arremesso verdadeiro% vs uso%) — jogadores de alto volume sacrificam eficiência?
SELECT
	nome_jogador,
    AVG(percentual_arremesso_verdadeiro) AS media_percentual_arremesso_verdadeiro,
    AVG(percentual_uso) AS media_percentual_uso
FROM
	temporadas
GROUP BY
	nome_jogador
ORDER BY media_percentual_arremesso_verdadeiro DESC, media_percentual_uso DESC;

-- Identificar os jogadores que mais evoluíram entre temporadas (maior aumento em pontos/rebotes/assistências)
With evolucao AS (
SELECT
	nome_jogador,
    temporada,
    ROUND(pontos - LAG(pontos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_pontos,
    ROUND(ressaltos - LAG(ressaltos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_ressaltos,
    ROUND(assistencias - LAG(assistencias) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_assistencia
FROM
	temporadas
)
-- Maior evolução em pontos
SELECT 
	nome_jogador,
    temporada,
    diferenca_pontos
FROM
	evolucao
WHERE
	diferenca_pontos > 0
ORDER BY diferenca_pontos DESC
LIMIT 10;
/*  MarShon Brooks em 2017 melhorou sua média de pontos em 15,6. Ele foi seguido de perto por Paul George,
que em 2015 melhorou sua pontuação em 14.3, assim como Khyri Thomas.
JaKarr Sampson em 2018 melhorou sua pontuação em 15,3.
*/

-- Maior evolução em rebotes
With evolucao AS (
SELECT
	nome_jogador,
    temporada,
    ROUND(pontos - LAG(pontos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_pontos,
    ROUND(ressaltos - LAG(ressaltos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_ressaltos,
    ROUND(assistencias - LAG(assistencias) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_assistencia
FROM
	temporadas
)
SELECT 
	nome_jogador,
    temporada,
    diferenca_ressaltos
FROM
	evolucao
WHERE
	diferenca_ressaltos > 0
ORDER BY diferenca_ressaltos DESC
LIMIT 10;
/*  Entre os jogadores que mais evoluíram em rebotes, Julius Randle em 2015 aumentou sua média em 10,2.
Danny Fortson em 2000 melhorou seus rebotes em 9,6.
Jaylen Hoard em 2021 melhorou seus rebotes em 8,6.
*/

-- Maior evolução em assistências por jogo
With evolucao AS (
SELECT
	nome_jogador,
    temporada,
    ROUND(pontos - LAG(pontos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_pontos,
    ROUND(ressaltos - LAG(ressaltos) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_ressaltos,
    ROUND(assistencias - LAG(assistencias) OVER (PARTITION BY nome_jogador ORDER BY temporada), 3) AS diferenca_assistencia
FROM
	temporadas
)
SELECT 
	nome_jogador,
    temporada,
    diferenca_assistencia
FROM
	evolucao
WHERE
	diferenca_assistencia > 0
ORDER BY diferenca_assistencia DESC
LIMIT 10;

/* Skylar Mays em 2022 melhorou suas assistências em 7,7
Kendall Marshall em 2013 melhorou em 5,8
*/

/*
Comparações entre Eras e Equipes

* Comparar o tamanho médio dos jogadores (altura/peso) entre os anos 1990, 2000, 2010 e 2020.
* Identificar quais equipes produzem consistentemente jogadores de alto desempenho.
* Comparar novatos e veteranos — como suas contribuições diferem?
  */

-- Comparar o tamanho médio dos jogadores (altura/peso) entre os anos 1990, 2000, 2010 e 2020.
SELECT
	CONCAT(FLOOR(temporada / 10) * 10, "s") AS era,
	ROUND(AVG(altura), 3) AS media_altura,
    ROUND(AVG(peso), 3) AS media_peso
FROM
	temporadas
GROUP BY 
	era;
/*
Houve uma redução na altura e no peso médios dos jogadores dos anos 1990 até os anos 2020.
Os anos 2000 apresentaram as maiores médias tanto de peso quanto de altura.
A geração atual de jogadores (anos 2020) é a mais baixa e leve em comparação com eras anteriores.
*/

-- Comparar o desempenho médio entre os anos 1990, 2000, 2010 e 2020.
SELECT
	CONCAT(FLOOR(temporada / 10) * 10, "s") AS era,
	ROUND(AVG(pontos), 3) AS m_pts,
    ROUND(AVG(ressaltos), 3) AS m_ressaltos,
    ROUND(AVG(assistencias), 3) AS m_ass,
    ROUND(AVG(percentual_ressaltos_ofensivos), 3) AS m_pct_ress_ofens,
    ROUND(AVG(percentual_ressaltos_defensivos), 3) AS m_pct_ress_def,
    ROUND(AVG(classificacao_liquida), 3) AS m_classificacao_liquida,
    ROUND(AVG(percentual_uso), 3) AS m_pct_uso,
	ROUND(AVG(percentual_arremesso_verdadeiro), 3) AS m_pct_arr_verdadeiro,
    ROUND(AVG(percentual_assistencias), 3) AS m_pct_ass    
FROM
	temporadas
GROUP BY 
	era;
/*
Apesar da redução física ao longo das eras, os índices de desempenho, como média de pontos, aumentaram
de 8,432 nos anos 1990 para 10,142 nos anos 2020.
A média de assistências por jogo também aumentou de 1,869 nos anos 1990 para 2,263 nos anos 2020.
A media de classificacao_liquida também apresentou melhoria, saindo de -1,39 nos anos 2000 para -1,233 nos anos 2020.
A media de percentual de uso apresentou uma queda constante de 0,192 nos anos 1990 para 0,186 nos anos 2020.
A media de percentual de arremesso verdadeiro também aumentou gradualmente de 0,49 nos anos 1990 para 0,55 nos anos 2020.
*/

-- Identificar quais equipes produzem consistentemente jogadores de alto desempenho.
-- Os melhores desempenhos serão os 5 melhores jogadores em uma categoria ao longo das temporadas
DROP VIEW IF EXISTS ranking_performances;
CREATE VIEW  ranking_performances AS(
	SELECT
		temporada,
		nome_jogador,
        abreviacao_team AS team,
		pontos,
		ressaltos,
		assistencias,
		classificacao_liquida,
		percentual_ressaltos_ofensivos,
		percentual_ressaltos_defensivos,
		percentual_uso,
		percentual_arremesso_verdadeiro,
		percentual_assistencias,
		RANK() OVER (PARTITION BY temporada ORDER BY pontos DESC) AS pts_ranking,
		RANK() OVER (PARTITION BY temporada ORDER BY ressaltos DESC) AS ress_ranking,
		RANK() OVER (PARTITION BY temporada ORDER BY assistencias DESC) AS ass_ranking,
		RANK() OVER (PARTITION BY temporada ORDER BY classificacao_liquida DESC) AS classificacao_liquida_ranking,
        RANK() OVER (PARTITION BY temporada ORDER BY percentual_ressaltos_ofensivos DESC) AS ressaltos_ofensivos_ranking,
        RANK() OVER (PARTITION BY temporada ORDER BY percentual_ressaltos_defensivos DESC) AS ressaltoa_defensivos_ranking,
        RANK() OVER (PARTITION BY temporada ORDER BY percentual_uso DESC) AS uso_pct_ranking,
        RANK() OVER (PARTITION BY temporada ORDER BY percentual_arremesso_verdadeiro DESC) AS arremesso_verdadeiro_pct_ranking,
        RANK() OVER (PARTITION BY temporada ORDER BY percentual_assistencias DESC) AS ass_pct_ranking
	FROM 
		temporadas
);

-- Verificando a view
SELECT  
	*
FROM 
ranking_performances
LIMIT 5;
-- Está funcionando corretamente.

-- Quais equipes produziram os melhores jogadores em pontos_por_jogo em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    pontos,
    pts_ranking
FROM
	ranking_performances
WHERE
	pts_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num_pt_ranks
FROM
	ranking_performances
WHERE 
	pts_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num_pt_ranks DESC;
-- LAL produziu 21 jogadores entre os top 5 ao longo dos anos. Em seguida vêm PHI e OKC, ambos com 12.

-- Quais equipes produziram os melhores reboteiros em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    ressaltos,
    ress_ranking
FROM
	ranking_performances
WHERE
	ress_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(*) AS num
FROM
	ranking_performances
WHERE 
	ress_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- MIN (12) e MIN (13) produziram vários dos melhores reboteiros ao longo dos anos.

-- Melhores armadores/criadores de jogadas
-- Quais equipes produziram os melhores jogadores em assistências por jogo em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    assistencias,
    ass_ranking
FROM
	ranking_performances
WHERE
	ass_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	ass_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- PHX lidera isoladamente com 19 jogadores liderando assistências por jogo ao longo dos anos. Seguido por WAS com 12.

-- Quais equipes produziram os jogadores com melhor classificacao_liquida em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    classificacao_liquida,
    classificacao_liquida_ranking
FROM
	ranking_performances
WHERE
	classificacao_liquida_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	classificacao_liquida_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- SAS e GSW lideram com 14 e 13  jogadores ao longo das temporadas.

-- Quais equipes produziram os melhores reboteiros ofensivos em cada temporada?
SELECT
temporada,
	team,
    nome_jogador,
    percentual_ressaltos_defensivos,
    ressaltos_ofensivos_ranking
FROM
	ranking_performances
WHERE
	ressaltos_ofensivos_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	ressaltos_ofensivos_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- DET, NYK e MEM possuem respectivamente 10, 9 e 8 jogadores entre os top 5 ao longo dos anos.

-- Quais equipes produziram os melhores reboteiros defensivos em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    percentual_ressaltos_defensivos,
    ressaltoa_defensivos_ranking
FROM
	ranking_performances
WHERE
	ressaltoa_defensivos_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	ressaltoa_defensivos_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- ORL, CLE, DEN e POR lideram com 10, 9, 8 e 8 respectivamente.

-- Quais equipes produziram os jogadores com maior uso% em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    percentual_uso,
    uso_pct_ranking
FROM
	ranking_performances
WHERE
	uso_pct_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	uso_pct_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- LAL (18) e PHI (13) lideram. 

-- Quais equipes produziram os jogadores com maior percentual_arremesso_verdadeiro em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    percentual_arremesso_verdadeiro,
    arremesso_verdadeiro_pct_ranking
FROM
	ranking_performances
WHERE
	arremesso_verdadeiro_pct_ranking <= 5;
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	arremesso_verdadeiro_pct_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- BOS (11) e NYK (10) produziram os melhores percentual_arremesso_verdadeiro ao longo dos anos.

-- Quais equipes produziram os jogadores com maior percentual_assistencias em cada temporada?
SELECT
	temporada,
	team,
    nome_jogador,
    percentual_assistencias,
    ass_pct_ranking
FROM
	ranking_performances
WHERE
	ass_pct_ranking <= 5;
    
-- Agrupado por equipes
SELECT
	team,
    COUNT(team) AS num
FROM
	ranking_performances
WHERE 
	ass_pct_ranking <= 5
GROUP BY 
	team
ORDER BY 
	num DESC;
-- WAS (13), PHX(13) e UTA possuem 10 jogadores entre os top 5 ao longo dos anos.

-- Comparar novatos e veteranos — como suas contribuições diferem?
/*
Em termos da NBA:
Um novato é um jogador em sua primeira temporada.
Um veterano é qualquer jogador com múltiplas temporadas de experiência.
*/

-- Encontrar a temporada de estreia de cada jogador
CREATE TEMPORARY TABLE temp_estreia AS
SELECT
	nome_jogador,
    MIN(temporada) AS temp_novato
FROM
	temporadas
GROUP BY
	nome_jogador;
    
-- Marcar temporadas de novato e veterano
DROP TEMPORARY TABLE IF EXISTS nivel_experiencia;
CREATE TEMPORARY TABLE nivel_experiencia AS (
SELECT
	temp.nome_jogador,
    temp.idade,
    temp.jogos,
    temp.pontos,
    temp.assistencias,
    temp.ressaltos,
    temp.classificacao_liquida,
    temp.percentual_ressaltos_ofensivos,
    temp.percentual_ressaltos_defensivos,
    temp.percentual_uso,
    temp.percentual_arremesso_verdadeiro,
    temp.percentual_assistencias,
    temp.temporada,
    CASE WHEN temp.temporada = t_e.temp_novato THEN "Novato" ELSE "Veterano" END AS nivel_experiencia_jogador
FROM
	temporadas temp
JOIN 
	temp_estreia t_e
    ON temp.nome_jogador = t_e.nome_jogador
);

SELECT
	nivel_experiencia_jogador,
	ROUND(AVG(pontos), 3) AS m_pts,
    ROUND(AVG(ressaltos), 3) AS m_ress,
    ROUND(AVG(assistencias), 3) as m_ass,
    ROUND(AVG(classificacao_liquida), 3) as m_classificacao_liquida,
    ROUND(AVG(percentual_ressaltos_ofensivos), 3) as m_pct_ress_o,
    ROUND(AVG(percentual_ressaltos_defensivos), 3) as m_pct_ress_d,
    ROUND(AVG(percentual_uso), 3) as m_uso_pct,
    ROUND(AVG(percentual_arremesso_verdadeiro), 3) as m_pct_arr_verdadeiro,
    ROUND(AVG(percentual_assistencias), 3) as m_pct_ass
FROM
	nivel_experiencia n_e
GROUP BY
	nivel_experiencia_jogador;
-- Veteranos possuem melhores contribuições em todos os níveis em comparação aos novatos.

-- Verificar o nível de experiência por eras: anos 1990, 2000, 2010 e 2020
SELECT
	CONCAT(FLOOR(temporada / 10) * 10, "s") as era,
	nivel_experiencia_jogador,
	ROUND(AVG(pontos), 3) AS m_pts,
    ROUND(AVG(ressaltos), 3) AS m_ress,
    ROUND(AVG(assistencias), 3) as m_ass,
    ROUND(AVG(classificacao_liquida), 3) as m_classificacao_liquida,
    ROUND(AVG(percentual_ressaltos_ofensivos), 3) as m_pct_ress_o,
    ROUND(AVG(percentual_ressaltos_defensivos), 3) as m_pct_ress_d,
    ROUND(AVG(percentual_uso), 3) as m_uso_pct,
    ROUND(AVG(percentual_arremesso_verdadeiro), 3) as m_pct_arr_verdadeiro,
    ROUND(AVG(percentual_assistencias), 3) as m_pct_ass
FROM
	nivel_experiencia n_e
GROUP BY
	era, nivel_experiencia_jogador;
-- Ao analisar as contribuições entre as diferentes eras, os veteranos sempre superaram os novatos.
-- Isso não é surpreendente, já que veteranos possuem mais experiência que novatos.

/*
MVP 

* Usar um índice ponderado (ex.: 40% pontos, 30% rebotes/assistências, 30% eficiência) para encontrar o MVP de uma temporada.

* Montar o quinteto ideal (PG, SG, SF, PF, C) usando estatísticas de todas as temporadas.


  */

-- Usar um índice ponderado (ex.: 40% pontos, 30% rebotes/assistências, 30% eficiência) para encontrar o MVP de uma temporada.
DROP VIEW IF EXISTS MVP_seasonal_rankings;

CREATE VIEW MVP_temp_rankings AS (
	SELECT
		nome_jogador,
		temporada,
		performance,
		RANK() OVER (PARTITION BY temporada ORDER BY performance DESC) AS MVP_ranK
	FROM (
		SELECT
			nome_jogador,
			temporada,
			ROUND((0.4 * pontos) + 0.3 * (0.4 * ressaltos + 0.6 * assistencias) + (0.3 * percentual_arremesso_verdadeiro), 2) AS performance 
		FROM 
			temporadas
	) AS MVP_rankings
);
-- O Hall da Fama dos MVPs da NBA -
SELECT
	temporada,
	nome_jogador,
	performance
FROM 
	MVP_temp_rankings
WHERE
	MVP_rank = 1;

-- Quantos vencedores únicos de MVP tivemos?
SELECT
	COUNT(DISTINCT nome_jogador) AS vencedores_unicos
FROM
	mvp_temp_rankings
WHERE
	MVP_rank = 1;
-- Houve 13 MVPs únicos entre 1996 e 2022.

-- Quantas vezes cada um dos 13 vencedores ganhou?
SELECT
	nome_jogador,
    COUNT(*) AS vezes_vencidas
FROM
	mvp_temp_rankings
WHERE
	MVP_rank = 1
GROUP BY
	nome_jogador
ORDER BY 
	vezes_vencidas DESC;
-- LeBron James venceu 4 MVPs e pode ser considerado o GOAT no período analisado.

