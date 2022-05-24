-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.PH006_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

--All customers are in #segmentAssignment
-- select all acquire from the above and put in the relevant offer

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.ConsumerCombination cc
Inner join Warehouse.Relational.MCCList mcc
	On cc.MCCID = mcc.MCCID
Where MCCDesc = 'PET SHOPS - PET FOODS AND SUPPLIES'
And LocationCountry = 'GB'

CREATE CLUSTERED INDEX CIX_CC_ConsumerCombinationID ON #cc (ConsumerCombinationID)

--  Assign Shopper segments
If Object_ID('Warehouse.Selections.PH006_PreSelection') Is Not Null Drop Table Warehouse.Selections.PH006_PreSelection
Select cl.CINID
	 , cl.fanid
Into Warehouse.Selections.PH006_PreSelection
From (Select CL.CINID
		   , c.FanID
	  From warehouse.Relational.Customer c
	  Inner join warehouse.Relational.CINList cl
		on c.SourceUID = cl.CIN
	  where c.CurrentlyActive = 1
	  And c.sourceuid Not In (Select Distinct SourceUID
							  From Warehouse.Staging.Customer_DuplicateSourceUID)
	  Group by CL.CINID
			 , c.FanID) CL
Inner Join (Select ct.CINID
			From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
			Join  #cc cc
				On cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Where  0 < ct.Amount
			And TranDate > dateadd(year,-1,getdate())
			Group by ct.CINID) b
	On cl.CINID = b.CINID

END