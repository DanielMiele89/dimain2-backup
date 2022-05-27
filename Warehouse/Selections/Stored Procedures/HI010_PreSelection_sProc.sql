﻿-- =============================================
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (1648,2091,2168,2793,2794,2796);

DECLARE @Date DATE = DATEADD(MONTH,-18,GETDATE())

IF OBJECT_ID('SANDBOX.BASTIENC.HOLIDAY_INN') IS NOT NULL DROP TABLE SANDBOX.BASTIENC.HOLIDAY_INN;
SELECT DISTINCT A.CINID --,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO SANDBOX.BASTIENC.HOLIDAY_INN
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
join Warehouse.Relational.CINList cin on cin.CINID = a.CINID
JOIN Warehouse.Relational.Customer C on C.SourceUID = cin.CIN
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date	