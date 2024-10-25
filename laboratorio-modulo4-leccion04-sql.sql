-- Ejercicio 1. Queries Generales

-- 1.1. Calcula la temperatura mínima y máxima de todos los municipios por fecha
SELECT *
FROM (SELECT  m.nombre AS municipio,f.fecha::DATE, MAX(temperatura),MIN(temperatura)
		FROM tiempo t
		INNER JOIN fechas f 
		ON f.id_fecha = t.id_fecha
		INNER JOIN municipios m 
		ON m.id_municipio = t.id_municipio 
		GROUP BY m.nombre, f.fecha::DATE)	
ORDER BY municipio;

-- 1.2. Obtén los municipios en los cuales coincidan las medias de la sensación térmica y de la temperatura. 
SELECT *  
FROM(
	SELECT m.nombre,
	ROUND(AVG(t.sensacion_termica),2) AS media_sensacion_termica,
	ROUND(AVG(t.temperatura),2) AS media_temperatura
	FROM tiempo t 
	INNER JOIN municipios m
	ON m.id_municipio = t.id_municipio
	GROUP BY m.id_municipio)
WHERE media_sensacion_termica = media_temperatura
ORDER BY media_temperatura DESC;

-- 1.3. Obtén el local más cercano de cada municipio
SELECT * 
FROM(
	SELECT m.nombre AS municipio,
	l.nombre AS local,
	l.distancia_al_centro AS distancia_al_centro_metros
	FROM municipios m 
	INNER JOIN lugares l
	ON m.id_municipio = l.id_municipio 
	WHERE l.distancia_al_centro = (
			SELECT MIN(l2.distancia_al_centro)
			FROM lugares l2 
			WHERE l2.id_municipio = m.id_municipio))
ORDER BY distancia_al_centro_metros DESC;
	
-- 1.4. Localiza los municipios que posean algún localizador a una distancia mayor de 2000 y que posean al menos 25 locales.

SELECT * FROM (
			SELECT m.nombre, l.nombre AS local ,SUM(l.id_municipio) AS total_locales, COUNT(l.id_municipio) AS locales_mayores_2000_metros
			FROM lugares l 
			INNER JOIN municipios m 
			ON m.id_municipio = l.id_municipio 
			WHERE l.distancia_al_centro >= 2000
			GROUP BY l.id_municipio,m.id_municipio,l.nombre 
)
WHERE total_locales > 25 

-- 1.5. Teniendo en cuenta que el viento se considera leve con una velocidad media de entre 6 y 20 km/h, moderado con una media de entre 21 y 40 km/h,
--fuerte con media de entre 41 y 70 km/h y muy fuerte entre 71 y 120 km/h. Calcula cuántas rachas de cada tipo tenemos en cada uno de los días.
--Este ejercicio debes solucionarlo con la sentencia CASE de SQL (no la hemos visto en clase, por lo que tendrás que buscar la documentación). 
CREATE TEMPORARY TABLE TablaVelocidadViento AS
	SELECT f.fecha ,t.velocidad_del_viento,
		CASE 
		WHEN t.velocidad_del_viento BETWEEN 6 AND 20 THEN 'Viento leve'
		WHEN t.velocidad_del_viento BETWEEN 21 AND 40 THEN 'Viento moderado'
		WHEN t.velocidad_del_viento BETWEEN 41 AND 70 THEN 'Viento Fuerte'
		ELSE 'Viento muy Fuerte'
		END AS tipo_viento
	FROM tiempo t
	INNER JOIN fechas f 
	ON f.id_fecha = t.id_fecha
	ORDER BY f.fecha 

SELECT fecha,tipo_viento, COUNT(tipo_viento)
FROM tablavelocidadviento
GROUP BY fecha,tipo_viento
ORDER BY fecha,tipo_viento

-- Ejercicio 2. Vistas

-- 2.1. Crea una vista que muestre la información de los locales que tengan incluido el código postal en su dirección. 
CREATE VIEW LocalesConCodigoPostal AS
	SELECT * FROM lugares l WHERE regexp_like(l.direccion ,'\d\d\d\d\d');
	
SELECT *
FROM localesconcodigopostal

-- 2.2. Crea una vista con los locales que tienen más de una categoría asociada.
CREATE VIEW LocalesConMasDeUnaCategoria AS
SELECT l.nombre AS lugar, COUNT(l.id_categoria) AS categorias_asociadas
FROM lugares l
GROUP BY l.nombre
HAVING COUNT(l.id_categoria) > 1
ORDER BY l.nombre;

SELECT * FROM LocalesConMasDeUnaCategoria

-- 2.3. Crea una vista que muestre el municipio con la temperatura más alta de cada día
CREATE VIEW municipioTempMasAlta AS
SELECT fecha,MAX(temperatura_maxima)
	FROM (
	SELECT f.fecha::DATE ,m.nombre AS municipio, MAX(t.temperatura) AS temperatura_maxima 
	FROM tiempo t 
	INNER JOIN fechas f 
	ON t.id_fecha = f.id_fecha 
	INNER JOIN municipios m 
	ON m.id_municipio = t.id_municipio 
	GROUP BY f.fecha::DATE,m.id_municipio 
	ORDER BY fecha)
GROUP BY fecha

SELECT * FROM municipioTempMasAlta

-- NO SE HACERLO me rindo

-- 2.4. Crea una vista con los municipios en los que haya una probabilidad de precipitación mayor del 70% durante mínimo 7 horas.
CREATE VIEW precipitacion70masde7horas AS
	SELECT m.nombre AS municipio, COUNT(t.id_tiempo) AS horas_probabilidad
	FROM tiempo t
	INNER JOIN fechas f ON t.id_fecha = f.id_fecha
	INNER JOIN municipios m ON t.id_municipio = m.id_municipio
	WHERE t.probabilidad_de_tormenta > 70
	GROUP BY m.nombre
	HAVING COUNT(t.id_tiempo) >= 7
	ORDER BY horas_probabilidad DESC;

SELECT * FROM precipitacion70masde7horas


-- 2.5. Obtén una lista con los parques de los municipios que tengan algún castillo.
CREATE VIEW parquesquecontienencastillo AS
	SELECT l.nombre AS parque, m.nombre AS municipio
	FROM lugares l
	INNER JOIN municipios m ON l.id_municipio = m.id_municipio
	INNER JOIN categorias c ON l.id_categoria = c.id_categoria
	WHERE (c.nombre = 'Park' OR c.nombre = 'Castle') AND l.nombre LIKE '%astillo%'

SELECT * FROM parquesquecontienencastillo
-- ## Ejercicio 3. Tablas Temporales

-- 3.1. Crea una tabla temporal que muestre cuántos días han pasado desde que se obtuvo la información de la tabla AEMET.
CREATE TEMPORARY TABLE diastranscurridos AS
SELECT DISTINCT f.fecha::DATE AS fecha_obtencion,
       CURRENT_DATE - f.fecha::DATE AS dias_transcurridos
FROM fechas f
ORDER BY dias_transcurridos DESC

SELECT * FROM diastranscurridos
-- 3.2. Crea una tabla temporal que muestre los locales que tienen más de una categoría asociada e indica el conteo de las mismas
 
CREATE TEMPORARY TABLE localescategorias AS
SELECT l.nombre AS lugar, COUNT(l.id_categoria) AS cantidad_categorias
FROM lugares l
GROUP BY l.nombre
HAVING COUNT(l.id_categoria) > 1;

SELECT * FROM localescategorias
-- 3.3. Crea una tabla temporal que muestre los tipos de cielo para los cuales la probabilidad de precipitación mínima de los promedios de cada día es 5.


-- 3.4. Crea una tabla temporal que muestre el tipo de cielo más y menos repetido por municipio.

-- ## Ejercicio 4. SUBQUERIES

--4.1. Necesitamos comprobar si hay algún municipio en el cual no tenga ningún local registrado.
SELECT m.nombre AS municipio
FROM municipios m
WHERE m.id_municipio NOT IN (
    SELECT DISTINCT l.id_municipio
    FROM lugares l);

--4.2. Averigua si hay alguna fecha en la que el cielo se encuente "Muy nuboso con tormenta".

SELECT * 
FROM (
		SELECT f.fecha::DATE,m.nombre AS Municipio,ec.nombre AS estado_cielo
		FROM tiempo t
		INNER JOIN fechas f 
		ON f.id_fecha = t.id_fecha 
		INNER JOIN estado_cielo ec 
		ON t.id_estado_cielo = ec.id_estado_cielo
		INNER JOIN municipios m
		ON t.id_municipio = m.id_municipio)
WHERE estado_cielo = 'Muy nuboso con tormenta'

--4.3. Encuentra los días en los que el cielo sea diferente a "Muy nuboso con tormenta".

SELECT * 
FROM (
	SELECT f.fecha::DATE,m.nombre AS Municipio,ec.nombre AS estado_cielo
	FROM tiempo t
	INNER JOIN fechas f 
	ON f.id_fecha = t.id_fecha 
	INNER JOIN estado_cielo ec 
	ON t.id_estado_cielo = ec.id_estado_cielo
	INNER JOIN municipios m
	ON t.id_municipio = m.id_municipio
)
WHERE estado_cielo != 'Muy nuboso con tormenta';

--4.4. Selecciona el municipio con mayor número de locales.

SELECT * 
FROM (
	SELECT m.nombre AS municipio, COUNT(l.id_lugar) AS numero_locales
	FROM municipios m
	INNER JOIN lugares l ON m.id_municipio = l.id_municipio
	GROUP BY municipio)
ORDER BY numero_locales DESC
LIMIT 1;

--4.5. Obtén los municipios muya media de sensación térmica sea mayor que la media total.
SELECT nombre, media_temperatura
FROM (
    SELECT m.nombre, ROUND(AVG(t.sensacion_termica), 2) AS media_temperatura
    FROM tiempo t
    INNER JOIN municipios m ON t.id_municipio = m.id_municipio
    GROUP BY m.id_municipio
) AS municipio_media
WHERE media_temperatura > (
    SELECT ROUND(AVG(sensacion_termica), 2) AS media_total
    FROM tiempo t
);
--4.6. Selecciona los municipios con más de dos fuentes.
SELECT * 	
FROM (
	SELECT DISTINCT c.nombre AS categoria, m.nombre AS municipio, COUNT(c.nombre = 'Fountain') AS numero_fuentes
	FROM lugares l 
	INNER JOIN categorias c 
	ON l.id_categoria = c.id_categoria 
	INNER JOIN municipios m 
	ON l.id_municipio = m.id_municipio 
	GROUP BY c.nombre, m.nombre ) 
WHERE categoria = 'Fountain';

--4.7. Localiza la dirección de todos los estudios de cine que estén abiertod en el municipio de "Madrid".
SELECT * 	
FROM (
	SELECT m. nombre AS municipio,l.nombre AS local, c.nombre AS categoria
	FROM lugares l 
	INNER JOIN categorias c 
	ON l.id_categoria = c.id_categoria 
	INNER JOIN municipios m 
	ON l.id_municipio = m.id_municipio)
WHERE municipio = 'Madrid' AND categoria = 'Film Studio';

--4.8. Encuentra la máxima temperatura para cada tipo de cielo.
SELECT * 
FROM(
	SELECT  ec.nombre AS estado_cielo ,MAX(t.temperatura) AS temperatura_maxima
	FROM tiempo t
	NATURAL JOIN estado_cielo ec 
	GROUP BY ec.nombre )
ORDER BY temperatura_maxima DESC;

--4.9. Muestra el número de locales por categoría
SELECT *
FROM (
	SELECT c.nombre , COUNT(l.id_categoria) AS num_locales_por_categoría
	FROM lugares l 
	INNER JOIN categorias c
	ON l.id_categoria = c.id_categoria 
	GROUP BY c.id_categoria)
ORDER BY num_locales_por_categoría DESC;


--BONUS. 4.10. Encuentra los municipios que tengan más de 3 parques, los cuales se encuentren a una distancia menor 
--de las coordenadas de su municipio correspondiente que la del Parque Pavia. Esta parte no la puedo hacer xd
--Además, el cielo debe estar despejado a las 12.

SELECT *
FROM( 
	SELECT m.nombre AS municipio, COUNT(l.id_lugar) AS numero_parques
	FROM lugares l
	INNER JOIN categorias c
	ON l.id_categoria = c.id_categoria 
	INNER JOIN municipios m
	ON l.id_municipio = m.id_municipio 
	WHERE c.nombre = 'Park'
	GROUP BY m.nombre)
ORDER BY numero_parques DESC


