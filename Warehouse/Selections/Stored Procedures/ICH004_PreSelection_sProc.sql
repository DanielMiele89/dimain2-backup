﻿-- =============================================

IF OBJECT_ID('tempdb..#CC4') IS NOT NULL DROP TABLE #CC4;
SELECT ConsumerCombinationID
INTO #CC4
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (3306,3316,3218,3322,2796);

DECLARE @Date DATE = DATEADD(MONTH,-18,GETDATE())

IF OBJECT_ID('SANDBOX.BASTIENC.intercontinental') IS NOT NULL DROP TABLE SANDBOX.BASTIENC.intercontinental;
SELECT DISTINCT A.CINID --,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO SANDBOX.BASTIENC.intercontinental
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
join Warehouse.Relational.CINList cin on cin.CINID = a.CINID
JOIN Warehouse.Relational.Customer C on C.SourceUID = cin.CIN
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC4)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date