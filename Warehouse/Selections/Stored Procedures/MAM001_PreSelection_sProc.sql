﻿-- =============================================

/*
	DECLARE VARIABLES
*/

DECLARE @LockdownEndDate DATE = '2020-07-04'
/*
	#CC TABLES
*/

IF OBJECT_ID('TEMPDB..#CC') IS NOT NULL DROP TABLE #CC
SELECT	 CC.ConsumerCombinationID
		, B.BrandID
		, B.BrandName
INTO	#CC
FROM	Warehouse.Relational.ConsumerCombination CC
JOIN	Warehouse.Relational.Brand B
	ON CC.BrandID = B.BrandID
WHERE	B.BrandID IN (266)

CREATE CLUSTERED INDEX CIX_CC ON #CC(ConsumerCombinationID)

/*
	1. Shoppers
*/


IF OBJECT_ID('TEMPDB..#Shoppers') IS NOT NULL DROP TABLE #Shoppers
SELECT	DISTINCT CINID
INTO #Shoppers
FROM [Relational].[ConsumerTransaction_MyRewards] ct
WHERE EXISTS (SELECT 1 FROM #CC cc WHERE cc.ConsumerCombinationID = ct.ConsumerCombinationID)
AND ct.TranDate > @LockdownEndDate

CREATE CLUSTERED INDEX CIX_CC ON #Shoppers(CINID)



IF OBJECT_ID('TEMPDB..#Customers') IS NOT NULL DROP TABLE #Customers
SELECT	 FanID
INTO #Customers
FROM Warehouse.Relational.Customer C
WHERE NOT EXISTS (	SELECT 1
					FROM Warehouse.Relational.CINList CIN
					INNER JOIN #Shoppers sh
						ON CIN.CINID = sh.CINID