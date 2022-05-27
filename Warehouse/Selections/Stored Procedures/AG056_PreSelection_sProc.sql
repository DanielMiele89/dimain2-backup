-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure  [Selections].[AG056_PreSelection_sProc]
AS
BEGIN
	SET ANSI_WARNINGS OFF;

	
IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC

SELECT    
   br.BrandID
 , br.BrandName
 , cc.ConsumerCombinationID
 , MID
    , Narrative
    , MCCCategory
    , MCCDesc
Into #CC
FROM 
 Warehouse.Relational.ConsumerCombination cc
 INNER JOIN Warehouse.Relational.MCCList mcc
        ON cc.MCCID = mcc.MCCID
 Left join Warehouse.Relational.Brand br
  on br.BrandID = cc.BrandID
WHERE
 Narrative LIKE '%golf%'
    AND LocationCountry = 'GB'

CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


--  Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment



Select  cl.CINID
   
   ,cl.fanid


Into  #segmentAssignment
From  ( select CL.CINID
      ,cu.FanID
    from warehouse.Relational.Customer cu
    INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
    where cu.CurrentlyActive = 1
     and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
    group by CL.CINID, cu.FanID
   ) CL

inner Join ( Select  ct.CINID
            
                
        
    From  Warehouse.Relational.ConsumerTransaction_myrewards ct with (nolock)
    Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
    Where  0 < ct.Amount

       and TranDate >= dateadd(year,-2,getdate())
    group by ct.CINID ) b
on cl.CINID = b.CINID


WHERE NOT EXISTS (SELECT 1 FROM sandbox.matt.american_golf_comp_steal_pt1_180524 d WHERE cl.CINID = d.CINID) -- remove members from other campaign.
ORDER BY CINID
  ,fanid


	If object_id('Warehouse.Selections.AG056_PreSelection') is not null drop table Warehouse.Selections.AG056_PreSelection
	Select FanID
	Into Warehouse.Selections.AG056_PreSelection
	From #segmentAssignment

END

/*

Select FanID
Into #CurrentSelection
From Warehouse.Relational.IronOfferMember iom
Inner join Warehouse.Relational.Customer cu
	on iom.CompositeID = cu.CompositeID
Where IronOfferID in (13698,13699,13700,13697)
And StartDate = '2018-05-24 00:00:00.000'


Select Case when a55.fanid is null then 'selected' else 'excluded' end as status
	 , Count(Distinct a56.FanID) as cust
From Warehouse.Selections.AG056_PreSelection a56
Inner join (Select FanID from [Segmentation].[Roc_Shopper_Segment_Members] Where PartnerID = 3756 And ShopperSegmentTypeID = 7 and EndDate is null) s
	on a56.fanid = s.FanID
Left join #CurrentSelection a55
	on a56.fanid = a55.fanid
Group by Case when a55.fanid is null then 'selected' else 'excluded' end


*/
