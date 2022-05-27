﻿-- =============================================

SELECT * 
FROM Warehouse.Relational.BRAND 
WHERE BrandName LIKE '%Marriott%' --1652
OR BrandName LIKE '%Hilton%' --2062
OR BrandName LIKE '%Sheraton%' -- 2800
OR BrandName LIKE '%Radisson%' --2092
OR BrandName LIKE '%Thistle%' --439
OR BrandName LIKE '%De Vere%' -- 2801


IF OBJECT_ID('tempdb..#CC3') IS NOT NULL DROP TABLE #CC3;
SELECT ConsumerCombinationID
INTO #CC3
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (1652,2062,2800,2092,439,2801);

DECLARE @Date DATE = DATEADD(MONTH,-18,GETDATE())

IF OBJECT_ID('SANDBOX.BASTIENC.CROWNE_PLAZA_HOTEL_INDIGO') IS NOT NULL DROP TABLE SANDBOX.BASTIENC.CROWNE_PLAZA_HOTEL_INDIGO;
SELECT DISTINCT A.CINID --,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO SANDBOX.BASTIENC.CROWNE_PLAZA_HOTEL_INDIGO
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
join Warehouse.Relational.CINList cin on cin.CINID = a.CINID
JOIN Warehouse.Relational.Customer C on C.SourceUID = cin.CIN
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC3)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date	