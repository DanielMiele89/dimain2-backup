-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[OO006_PreSelection_sProc]
AS
BEGIN

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	Select   br.BrandID
	  , br.BrandName
	  , cc.ConsumerCombinationID

	Into #CC
	From Warehouse.Relational.Brand br
	Join Warehouse.Relational.ConsumerCombination cc
	 on br.BrandID = cc.BrandID
	Order By br.BrandName

	CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)


	--if needed to do SoW
	Declare @MainBrand smallint = 2514  -- Main Brand 

	--  Assign Shopper segments
	If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
	Select   cl.CINID   -- keep CINID and FANID
	  , cl.fanid   -- only need these two fields for forecasting / targetting everything else is dependant on requirements
	  , Office_Outlet as 'Is within 25 mins of Office Outlet'
	  , Target_Store as 'Is within 25 mins of Target Store'
	  , Office_Outlet_Spend_last_24M

	Into  #segmentAssignment

	From (
	   select   CL.CINID
		 , cu.FanID
		 , case when Office_Outlet.fromsector is not null then 1 else 0 end as Office_Outlet
		 , case when Office_DT.fromsector is not null then 1 else 0 end as Target_Store
   
		 from warehouse.Relational.Customer cu
	   INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN

     
	   left join 
		 (select distinct dtm.fromsector 
		 from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
		 where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
		   from  warehouse.relational.outlet
		   WHERE  --partnerid = 4715) AND 
		   dtm.DriveTimeMins <= 25
		   ) )
  
	   Office_Outlet on Office_Outlet.FromSector = cu.PostalSector  
  
	   left join 
		 (select distinct dtm.FromSector
		  from warehouse.relational.DriveTimeMatrix DTM
		  where DriveTimeMins <= 25 
		  and ToSector IN ('E6 7', 'CM1 1', 'NE11 9', 'BN23 6', 'CF24 1', 'NW2 6', 'DL9 3', 'E11 9')
    
		) Office_DT on Office_DT.FromSector = cu.PostalSector
	 where   cu.CurrentlyActive = 1
	   and  cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
	  ) CL


	left Join ( Select    ct.CINID
			 , sum(case when cc.brandid = @MainBrand   
			  then ct.Amount else 0 end) as MainBrand_sales
			 , max(case when cc.BrandID = @MainBrand
			 and TranDate  > dateadd(month,-24,getdate()) then 1 else 0 end) as Office_Outlet_Spend_last_24M
                     
		From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
	Join  #cc cc 
		 on cc.ConsumerCombinationID = ct.ConsumerCombinationID
  
	   Where  
		0 < ct.Amount
  
		--and TranDate  > dateadd(month,-12,getdate())

	   group by ct.CINID ) b
	on cl.CINID = b.CINID


	 select   count(*) as 'Number of Customers'
		, [Is within 25 mins of Office Outlet]
	  , [Is within 25 mins of Target Store]
	  , Office_Outlet_Spend_last_24M

  
	from #segmentAssignment
	group by
		[Is within 25 mins of Office Outlet]
	  , [Is within 25 mins of Target Store]
	  , Office_Outlet_Spend_last_24M

	If Object_ID('Warehouse.Selections.OO006_PreSelection') Is Not Null Drop Table Warehouse.Selections.OO006_PreSelection
	Select FanID
	Into Warehouse.Selections.OO006_PreSelection
	From #segmentAssignment
	Where [Is within 25 mins of Target Store] = 0

END