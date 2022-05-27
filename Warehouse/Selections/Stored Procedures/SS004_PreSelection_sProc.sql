﻿-- =============================================

--SELECT * 
--FROM Warehouse.Relational.BRAND 
--WHERE BrandName LIKE '%airbnb%' --1831
--OR BrandName LIKE '%wyndham vacation%' --2360
--OR BrandName LIKE '%Interactive resort%' -- 2407



IF OBJECT_ID('tempdb..#CC5') IS NOT NULL DROP TABLE #CC5;
SELECT ConsumerCombinationID
INTO #CC5
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (1831,2360,2407);

DECLARE @Date DATE = DATEADD(MONTH,-18,GETDATE())

IF OBJECT_ID('SANDBOX.BASTIENC.staybridge') IS NOT NULL DROP TABLE SANDBOX.BASTIENC.staybridge;
SELECT DISTINCT A.CINID --,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO SANDBOX.BASTIENC.staybridge
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
join Warehouse.Relational.CINList cin on cin.CINID = a.CINID
JOIN Warehouse.Relational.Customer C on C.SourceUID = cin.CIN
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC5)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date