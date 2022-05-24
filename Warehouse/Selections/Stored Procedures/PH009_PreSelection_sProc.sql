-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-04-17>-- Description: < sProc to run preselection code per camapign >-- =============================================Create Procedure Selections.PH009_PreSelection_sProcASBEGIN--All customers are in #segmentAssignment
-- select all acquire from the above and put in the relevant offer
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.ConsumerCombination cc
INNER JOIN Warehouse.Relational.MCCList mcc
 ON cc.MCCID = mcc.MCCID
Where MCCDesc = 'PET SHOPS - PET FOODS AND SUPPLIES'
AND LocationCountry = 'GB'

create clustered index IONXC on #CC (consumercombinationID)


If Object_ID('tempdb..#EligibleCustomers') IS NOT NULL DROP TABLE #EligibleCustomers
select CL.CINID
	 , c.FanID
INTO #EligibleCustomers
from Relational.Customer c
INNER JOIN Relational.CINList cl 
	ON c.SourceUID = cl.CIN
where c.CurrentlyActive = 1
and c.sourceuid NOT IN (select distinct sourceuid 
						from warehouse.Staging.Customer_DuplicateSourceUID )
--and c.PostalSector in (select distinct dtm.fromsector 
-- from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
-- where dtm.tosector IN ('AL1 3')
-- AND dtm.DriveTimeMins < 25)
group by CL.CINID
	   , c.FanID

DECLARE @Date DATETIME = dateadd(year,-1,getdate())

-- Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select cl.CINID
	 , cl.FanID
	 , sales
Into #segmentAssignment
From #EligibleCustomers CL
inner Join (Select ct.CINID
				 , sum(ct.Amount) as 'sales' 
			From Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			Join #cc cc
				on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Where 0 < ct.Amount
			AND @Date < TranDate
			group by ct.CINID) b
	on cl.CINID = b.CINIDIf Object_ID('Warehouse.Selections.PH009_PreSelection') Is Not Null Drop Table Warehouse.Selections.PH009_PreSelectionSelect FanIDInto Warehouse.Selections.PH009_PreSelectionFrom #segmentAssignmentEND