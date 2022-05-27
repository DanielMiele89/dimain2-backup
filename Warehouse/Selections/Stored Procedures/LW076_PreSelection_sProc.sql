﻿-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW076_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (246) --L 246, STWC 2648
Order By br.BrandName

CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)

DECLARE @DATE_12 DATE = DATEADD(MONTH, -12, GETDATE())

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, case when trans = 1 then 1 else 0 end as Shopped_Once
Into		#segmentAssignment

From		(	select CL.CINID
						,cu.FanID
				from warehouse.Relational.Customer cu
				INNER JOIN warehouse.Relational.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from warehouse.Staging.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from warehouse.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from warehouse.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							
							, count(1) as trans 

									
								
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				Where		0 < ct.Amount
							and TranDate > @DATE_12
				group by ct.CINID ) b
on	cl.CINID = b.CINID

	if OBJECT_ID('tempdb..#Seg_asign') is not null drop table #Seg_asign
	select		 s.CINID
				, s.FanID
				, s.Shopped_Once
	into		#Seg_asign
	from		#segmentAssignment s


	if OBJECT_ID('tempdb..#Final') is not null drop table #Final
	select	 CINID
			, fanid
	into	#Final
	from	#Seg_asign
	where Shopped_Once = 1



	IF OBJECT_ID('sandbox.vernon.Lait_single_trans_150420') IS NOT NULL DROP TABLE sandbox.vernon.Lait_single_trans_150420

	select	 CINID
			, fanid
	into	sandbox.vernon.Lait_single_trans_150420
	from	#Final

	
	IF OBJECT_ID('tempdb..#PreSelection') IS NOT NULL DROP TABLE #PreSelection
	SELECT	FanID
	INTO #PreSelection
	FROM (	SELECT FanID
			FROM [Sandbox].[Vernon].[Lait_single_trans_150420]
			UNION
			SELECT	sg.FanID
			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
			WHERE PartnerID = 4721
			AND EndDate IS NULL
			AND ShopperSegmentTypeID IN (7, 8)) sIf Object_ID('Warehouse.Selections.LW076_PreSelection') Is Not Null Drop Table Warehouse.Selections.LW076_PreSelectionSelect FanIDInto Warehouse.Selections.LW076_PreSelectionFROM  #PRESELECTIONEND