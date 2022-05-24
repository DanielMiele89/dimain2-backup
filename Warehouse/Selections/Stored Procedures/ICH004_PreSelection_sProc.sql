-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.ICH004_PreSelection_sProcASBEGIN

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
AND TranDate >= @DateIf Object_ID('Warehouse.Selections.ICH004_PreSelection') Is Not Null Drop Table Warehouse.Selections.ICH004_PreSelectionSelect FanIDInto Warehouse.Selections.ICH004_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM SANDBOX.BASTIENC.intercontinental st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END