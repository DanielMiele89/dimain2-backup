-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.SS004_PreSelection_sProcASBEGIN

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
AND TranDate >= @DateIf Object_ID('Warehouse.Selections.SS004_PreSelection') Is Not Null Drop Table Warehouse.Selections.SS004_PreSelectionSelect FanIDInto Warehouse.Selections.SS004_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM SANDBOX.BASTIENC.staybridge st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END