-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.HI010_PreSelection_sProcASBEGIN
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
AND TranDate >= @Date	If Object_ID('Warehouse.Selections.HI010_PreSelection') Is Not Null Drop Table Warehouse.Selections.HI010_PreSelectionSelect FanIDInto Warehouse.Selections.HI010_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM SANDBOX.BASTIENC.HOLIDAY_INN st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END