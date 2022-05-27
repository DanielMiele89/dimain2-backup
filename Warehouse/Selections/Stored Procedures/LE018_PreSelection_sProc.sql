-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-07-12>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE Selections.LE018_PreSelection_sProcASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;
SELECT ConsumerCombinationID
INTO #CC
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (56,105,1724);


--customer who shopped at boen cotton & joules
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
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC)
AND CURRENTLYACTIVE = 1	
AND TranDate >= DATEADD(month,-24,getdate())
group by A.CINID,month(trandate),year(trandate);

-----customers who shopped m&S and debenhams
IF OBJECT_ID('tempdb..#CC1') IS NOT NULL DROP TABLE #CC1;
SELECT ConsumerCombinationID
INTO #CC1
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (116,274);

IF OBJECT_ID('tempdb..#CT1') IS NOT NULL DROP TABLE #CT1;
SELECT A.CINID,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO #CT1
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN (
		SELECT Warehouse.Relational.CINList.*, Warehouse.Relational.Customer.CurrentlyActive,Warehouse.Relational.Customer.SourceUID 
		FROM Warehouse.Relational.CINList 
		inner join Warehouse.Relational.Customer 
		on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN) as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC1)
AND CURRENTLYACTIVE = 1	
AND TranDate >= DATEADD(month,-24,getdate())
group by A.CINID,month(trandate),year(trandate);


-----customers who shopped at a fashion brand
IF OBJECT_ID('tempdb..#CC2') IS NOT NULL DROP TABLE #CC2;
SELECT ConsumerCombinationID
INTO #CC2
FROM warehouse.Relational.CONSUMERCOMBINATION
WHERE BRANDID IN (select BrandID from Warehouse.Relational.Brand where SectorID between 51 and 59);

IF OBJECT_ID('tempdb..#CT2') IS NOT NULL DROP TABLE #CT2;
SELECT A.CINID,month(trandate) as tran_month,year(trandate) as tran_year,sum(amount) as spend,count(*) as transactions
INTO #CT2
FROM warehouse.Relational.ConsumerTransaction_MyRewards AS A
INNER JOIN (
		SELECT Warehouse.Relational.CINList.*, Warehouse.Relational.Customer.CurrentlyActive,Warehouse.Relational.Customer.SourceUID 
		FROM Warehouse.Relational.CINList 
		inner join Warehouse.Relational.Customer 
		on Warehouse.Relational.Customer.SourceUID = Warehouse.Relational.CINList.CIN) as customer_table 
	on A.CINID = customer_table.CINID
WHERE amount >= 0
and CONSUMERCOMBINATIONiD IN (SELECT * FROM #CC2)
AND CURRENTLYACTIVE = 1	
AND TranDate >= DATEADD(month,-6,getdate())
group by A.CINID,month(trandate),year(trandate);


IF OBJECT_ID('Sandbox.BastienC.landsend') IS NOT NULL DROP TABLE Sandbox.BastienC.landsend;
select cinid
into Sandbox.BastienC.landsend
from (
	select cinid from #CT
	union 
	select #ct1.cinid from #ct1 join #ct2 on #ct1.cinid = #ct2.cinid) a

	
IF OBJECT_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment;
SELECT	FanID
INTO #SegmentAssignment
FROM Relational.customer cu
WHERE EXISTS (	SELECT 1
				FROM relational.cinlist cl
				INNER JOIN SANDBOX.BASTIENC.LANDSEND le
					ON cl.CINID = le.CINID
				WHERE cu.SourceUID = cl.CIN)If Object_ID('Warehouse.Selections.LE018_PreSelection') Is Not Null Drop Table Warehouse.Selections.LE018_PreSelectionSelect FanIDInto Warehouse.Selections.LE018_PreSelectionFROM  #SEGMENTASSIGNMENTEND