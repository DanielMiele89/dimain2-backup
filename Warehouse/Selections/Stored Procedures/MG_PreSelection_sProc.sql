-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure  Selections.MG_PreSelection_sProc
AS
BEGIN
	SET ANSI_WARNINGS OFF;

			--Please segment from #segmentassignment
			--'01.seg_1'
			--'02.seg_2'
			--'03.seg_3'
			--'04.seg_4'

			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			Select br.BrandID
				 , br.BrandName
				 , cc.ConsumerCombinationID
			Into #CC
			From Warehouse.Relational.Brand br
			Join Warehouse.Relational.ConsumerCombination cc
			 on br.BrandID = cc.BrandID
			Where br.BrandID in (2521,2522,2019,1050,2520,2523,24,2519,355,187,303,371,459,505)
			Order By br.BrandName

			CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID,ConsumerCombinationID)


			--Declare @MainBrand smallint = 485  -- Main Brand 

			--  Assign Shopper segments
			If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
			Select  cl.CINID
   
			   ,cl.fanid
			   ,case when seg_1_spender = 1 then '01.seg_1'
				 when seg_2_spender = 1 then '02.seg_2'
				 when seg_3_spender = 1 then '03.seg_3'
				 when seg_4_spender = 1 then '04.seg_4'
				 else '00.NA'
				end as segment

			Into  #segmentAssignment
			From  ( select CL.CINID
				  ,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN  warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
				 and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
				 --and cu.PostalSector in (select distinct dtm.fromsector 
				 -- from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
				 -- where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
				 --                                                         from  warehouse.relational.outlet
				 --                                                         WHERE  partnerid = 4265)--adjust to outlet)
				 --                                                         AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			   ) CL

			left Join ( Select  ct.CINID
				   , max(case when cc.brandid in (2521,2522,2019)
						then 1 else 0 end) as seg_1_spender
       
				   , max(case when cc.brandid in (1050,2520,2523)
						then 1 else 0 end) as seg_2_spender
       
				   , max(case when cc.brandid in (24,2519,355)
						then 1 else 0 end) as seg_3_spender
       
				   , max(case when cc.brandid in (187,303,371,459,505)
						then 1 else 0 end) as seg_4_spender         
        
				From  Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join  #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where  0 < ct.Amount
				   and TranDate > DATEADD(year, -1, GETDATE())
				group by ct.CINID ) b
			on cl.CINID = b.CINID

			If object_id('Warehouse.Selections.MG009_PreSelection') is not null drop table Warehouse.Selections.MG009_PreSelection
			Select FanID
			Into Warehouse.Selections.MG009_PreSelection
			From #segmentassignment
			Where segment = '01.seg_1'

			If object_id('Warehouse.Selections.MG010_PreSelection') is not null drop table Warehouse.Selections.MG010_PreSelection
			Select FanID
			Into Warehouse.Selections.MG010_PreSelection
			From #segmentassignment
			Where segment = '02.seg_2'

			If object_id('Warehouse.Selections.MG011_PreSelection') is not null drop table Warehouse.Selections.MG011_PreSelection
			Select FanID
			Into Warehouse.Selections.MG011_PreSelection
			From #segmentassignment
			Where segment = '03.seg_3'

			If object_id('Warehouse.Selections.MG012_PreSelection') is not null drop table Warehouse.Selections.MG012_PreSelection
			Select FanID
			Into Warehouse.Selections.MG012_PreSelection
			From #segmentassignment
			Where segment = '04.seg_4'

END


