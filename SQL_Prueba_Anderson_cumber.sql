---1. ¿Existen temporadas de mayor venta de productos?
 USE PRUEBA_NOMBRE_APELLIDO
SELECT Periodo, SUM(Valor)VALOR
FROM [dbo].[Consumo]
GROUP BY Periodo
ORDER BY 2 DESC


---2 ¿CuLes la participacion de los afiliados vs no afiliados en el consumo total?

SELECT AFILIACION,COUNT(AFILIACION)TOTAL_AFILIACION,SUM(VALOR)VALOR,(AVG(VALOR)*100)PARTICIPACION
FROM (
SELECT A.NumIdPersona,A.Valor,
CASE WHEN B.NumIdPersona IS NULL THEN 'NO AFILIADA'
ELSE 'AFILIADA' END 'AFILIACION'
FROM Consumo A
LEFT JOIN Persona B ON A.NumIdPersona = B.NumIdPersona
)CONSUMO
GROUP BY AFILIACION
ORDER BY 4 DESC


---3. ¿Cuál es el consumo total por unidad de negocio?						
SELECT UES, SUM(VALOR)VALOR, SUM(NUMTRANSACCIONES)CANTIDAD_TRANSACCIONES
FROM CONSUMO
GROUP BY UES
ORDER BY 1 DESC


---4. ¿Cuáles son las unidades y productos de mayor uso en cada categoría?	
SELECT B.Categoria,A.UES, A.Producto,SUM(A.NumTransacciones)TOTAL_TRANSACCION
FROM CONSUMO A
INNER JOIN Persona B ON A.NumIdPersona = B.NumIdPersona
GROUP BY A.UES, B.Categoria, A.Producto
ORDER BY 4 DESC


---5.Identifique los clientes (afiliados y no afiliados) con mayor frecuencia de uso y mayor valor neto de venta.

---MAYOR FRECUENCIA
SELECT A.NumIdPersona, 
CASE WHEN B.NumIdPersona IS NULL THEN 'NO AFILIADA'
ELSE 'AFILIADA' END 'AFILIACION',
SUM(A.NumTransacciones)TOTAL_TRANSACCION,SUM(A.VALOR)TOTAL_VALOR_VENTA
FROM Consumo A
LEFT JOIN Persona B ON A.NumIdPersona = B.NumIdPersona
GROUP BY A.NumIdPersona,B.NumIdPersona
ORDER BY 3 DESC

---MAYOR VALOR NETO
SELECT A.NumIdPersona, 
CASE WHEN B.NumIdPersona IS NULL THEN 'NO AFILIADA'
ELSE 'AFILIADA' END 'AFILIACION',
SUM(A.NumTransacciones)TOTAL_TRANSACCION,SUM(A.VALOR)TOTAL_VALOR_VENTA
FROM Consumo A
LEFT JOIN Persona B ON A.NumIdPersona = B.NumIdPersona
GROUP BY A.NumIdPersona,B.NumIdPersona
ORDER BY 4 DESC

--6. ¿Cómo ha sido el porcentaje histórico de penetración en la población afiliada de los servicios Colsubsidio?
WITH CONSUMOS_POR_TIPO_CLIENTE AS (
    -- Clasificar consumos entre afiliados y no afiliados
    SELECT 
        C.Periodo,
        CASE 
            WHEN P.NumIdPersona IS NOT NULL THEN 'Afiliado'
            ELSE 'No Afiliado'
        END AS Tipo_Cliente,
        COUNT(DISTINCT C.NumIdPersona) AS Clientes_Con_Consumo
    FROM Consumo C
    LEFT JOIN Persona P ON C.NumIdPersona = P.NumIdPersona
    GROUP BY 
        C.Periodo,
        CASE 
            WHEN P.NumIdPersona IS NOT NULL THEN 'Afiliado'
            ELSE 'No Afiliado'
        END
),
TOTALES_POR_TIPO AS (
    -- ¿Cómo ha sido el porcentaje histórico de penetración en la población afiliada de los servicios Colsubsidio?
    SELECT 
        Tipo_Cliente,
        SUM(Clientes_Con_Consumo) AS Total_Clientes_Historico
    FROM CONSUMOS_POR_TIPO_CLIENTE
    GROUP BY Tipo_Cliente
)
SELECT 
    CPTC.Periodo,
    CPTC.Tipo_Cliente,
    CPTC.Clientes_Con_Consumo,
    TPT.Total_Clientes_Historico,
    CAST(
        CASE 
            WHEN TPT.Total_Clientes_Historico > 0 THEN 
                (CPTC.Clientes_Con_Consumo * 100.0) / TPT.Total_Clientes_Historico
            ELSE 0
        END AS DECIMAL(5,2)
    ) AS Porcentaje_Penetracion
FROM CONSUMOS_POR_TIPO_CLIENTE CPTC
INNER JOIN TOTALES_POR_TIPO TPT ON CPTC.Tipo_Cliente = TPT.Tipo_Cliente
ORDER BY CPTC.Tipo_Cliente, CPTC.Periodo;

SELECT 
    CPTC.Periodo,
    CPTC.Clientes_Con_Consumo AS [Afiliados con Consumo],
    CAST(
        CASE 
            WHEN TPT.Total_Clientes_Historico > 0 THEN 
                (CPTC.Clientes_Con_Consumo * 100.0) / TPT.Total_Clientes_Historico
            ELSE 0
        END AS DECIMAL(5,2)
    ) AS [Porcentaje (%)]
FROM CONSUMOS_POR_TIPO_CLIENTE CPTC
INNER JOIN TOTALES_POR_TIPO TPT ON CPTC.Tipo_Cliente = TPT.Tipo_Cliente
WHERE CPTC.Tipo_Cliente = 'Afiliado'
ORDER BY CPTC.Periodo;

---7. ¿Cuáles son los productos más consumidos en el cada segmento poblacional?							
WITH PRODUCTOS_SEGMENTOS AS (

SELECT A.Producto, B.Segmento_poblacional,COUNT(A.PRODUCTO)CANTIDAD_PRODUCTO
FROM Consumo A
INNER JOIN Persona B ON A.NumIdPersona = B.NumIdPersona
GROUP BY B.Segmento_poblacional,A.Producto
),
RANGO_PRODUCTOS AS (
SELECT SEGMENTO_POBLACIONAL, PRODUCTO, CANTIDAD_PRODUCTO,
RANK() OVER(PARTITION BY SEGMENTO_POBLACIONAL ORDER BY CANTIDAD_PRODUCTO DESC)PRODUCTO_RANKING
FROM PRODUCTOS_SEGMENTOS
)
SELECT
SEGMENTO_POBLACIONAL, PRODUCTO, CANTIDAD_PRODUCTO,PRODUCTO_RANKING
FROM RANGO_PRODUCTOS
WHERE PRODUCTO_RANKING = 1
ORDER BY 1;


---8. ¿Cuáles son las mejores empresas en cuanto a consumo individual de sus empleados?							
WITH CONSUMO_PERSONA AS (
SELECT A.id_empresa,B.NumIdPersona,SUM(B.VALOR)CONSUMO_TOTAL_PERSONA 
FROM Persona A
INNER JOIN CONSUMO B ON A.NumIdPersona = B.NumIdPersona
GROUP BY A.id_empresa,B.NumIdPersona
),
CONSUMO_EMPRESA AS (
SELECT id_empresa,AVG(CONSUMO_TOTAL_PERSONA)CONSUMO_PROMEDIO_PERSONA
FROM CONSUMO_PERSONA
GROUP BY id_empresa
)
SELECT CE.id_empresa, CAST(CONSUMO_PROMEDIO_PERSONA AS INT)CONSUMO_PROMEDIO_PERSONA
FROM CONSUMO_PERSONA CP
INNER JOIN CONSUMO_EMPRESA CE ON CP.id_empresa = CE.id_empresa
ORDER BY CONSUMO_PROMEDIO_PERSONA DESC