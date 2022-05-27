-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-05-30>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.ML028_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (355,116,328,1070,486,130,148);

DECLARE @Date DATE = DATEADD(month,-13,getdate())

IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
SELECT A.CINID,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO #CT
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN (
		SELECT Warehouse.Relational.CINList.*, Warehouse.Relational.Customer.CurrentlyActive,Warehouse.Relational.Customer.SourceUID 
		FROM Warehouse.Relational.CINList 
		inner join Warehouse.Relational.Customer 
		on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN) as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT CONSUMERCOMBINATIONiD FROM #CC)
AND CURRENTLYACTIVE = 1	
AND TranDate >= @Date
group by A.CINID,month(trandate),year(trandate);


IF OBJECT_ID('Sandbox.BastienC.matalan_compsteal') IS NOT NULL DROP TABLE Sandbox.BastienC.matalan_compsteal;
select cinid
into Sandbox.BastienC.matalan_compsteal
from #CTIf Object_ID('Warehouse.Selections.ML028_PreSelection') Is Not Null Drop Table Warehouse.Selections.ML028_PreSelectionSelect FanIDInto Warehouse.Selections.ML028_PreSelectionFROM Relational.Customer cuWHERE EXISTS (	SELECT 1				FROM Sandbox.BastienC.matalan_compsteal st				INNER JOIN Relational.CINList cl					ON st.CINID = cl.CINID				WHERE cu.SourceUID = cl.CIN)END