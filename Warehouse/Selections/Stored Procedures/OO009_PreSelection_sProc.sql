-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2018-12-18>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
Create Procedure Selections.OO009_PreSelection_sProc
AS
BEGIN


IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC						
Select	br.BrandID					
		,br.BrandName				
		,cc.ConsumerCombinationID				
Into	#CC					
From	Warehouse.Relational.Brand br					
Join	Warehouse.Relational.ConsumerCombination cc					
	on	br.BrandID = cc.BrandID				
Where	br.BrandID IN (2514,375,492,2166)					
Order By br.BrandName						
						
						
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)						
						
--if needed to do SoW						
Declare @MainBrand smallint = 2514	 -- Main Brand					
						
--		Assign Shopper segments				
If Object_ID('tempdb..#SegmentAssignment') IS NOT NULL DROP TABLE #SegmentAssignment						
SELECT cl.CINID,						
	   cu.FanID,					
	   BrandName,					
	   Gender,					
	   AgeCurrent,					
	   AgeCurrentBandText					
						
INTO #SegmentAssignment						
						
FROM warehouse.Relational.Customer cu						
JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN						
						
LEFT JOIN (SELECT   ct.CINID,						
					SUM(ct.Amount) as sales,	
					BrandName,	
					COUNT(1) AS 'Transactions'	
						
			From Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)			
			Join #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID			
						
			Where 0 < ct.Amount			
			--and TranDate  > dateadd(month,-12,getdate())			
			and DATEADD(WEEK, -108, GETDATE()) < TranDate and TranDate < DATEADD(WEEK, -56, GETDATE())			
			group by ct.CINID, BrandName) b			
on	cl.CINID = b.CINID					
						
WHERE cu.CurrentlyActive = 1						
AND cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )						
						
						
						
						
If Object_ID('tempdb..#BackToWork') IS NOT NULL DROP TABLE #BackToWork						
SELECT	CINID,					
		fanid				
						
INTO #BackToWork		
FROM #SegmentAssignment		
WHERE Gender IN ('M','F')						
	  AND AgeCurrent >= 25					
						



If Object_ID('Warehouse.Selections.OO009_PreSelection') Is Not Null Drop Table Warehouse.Selections.OO009_PreSelection
Select FanID
Into Warehouse.Selections.OO009_PreSelection
From #BackToWork


END
