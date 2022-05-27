-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure Selections.CT040_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select br.BrandID
	 , br.BrandName
	 , cc.ConsumerCombinationID
Into #CC
From Warehouse.Relational.Brand br
Join Warehouse.Relational.ConsumerCombination cc
	on br.BrandID = cc.BrandID
Where br.BrandID in (83)
Order By br.BrandName

CREATE CLUSTERED INDEX CIX_CC_BrandIDConsumerCombinationID ON #cc (BrandID, ConsumerCombinationID)

If Object_ID('Warehouse.Selections.CT040_PreSelection') Is Not Null Drop Table Warehouse.Selections.CT040_PreSelection
Select FanID
Into Warehouse.Selections.CT040_PreSelection
From (Select CL.CINID
		   , cu.FanID
	  From warehouse.Relational.Customer cu
	  Inner join Warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
	  Where cu.CurrentlyActive = 1
	  And not exists (Select 1
					  From Warehouse.Staging.Customer_DuplicateSourceUID dsuid
					  Where cu.SourceUID = dsuid.SourceUID)
	  Group by CL.CINID
			 , cu.FanID) CL
Left Join (Select ct.CINID
		   From Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
		   Join #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		   Where 0 <= ct.Amount
		   Group by ct.CINID) b
	On cl.CINID = b.CINID
Where b.CINID is null

END
