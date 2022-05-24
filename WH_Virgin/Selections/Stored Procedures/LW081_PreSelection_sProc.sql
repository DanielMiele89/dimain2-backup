-- =============================================-- Author:  <Rory Francis>-- Create date: <2021-06-11>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE PROCEDURE [Selections].[LW081_PreSelection_sProc]ASBEGINIF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	br.BrandID
		,br.BrandName
		,cc.ConsumerCombinationID
Into	#CC
From	Warehouse.Relational.Brand br
Join	WH_Virgin.Trans.ConsumerCombination cc
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
				from WH_Virgin.Derived.Customer cu
				INNER JOIN WH_Virgin.Derived.CINList cl on cu.SourceUID = cl.CIN
				where cu.CurrentlyActive = 1
					and cu.sourceuid NOT IN (select distinct sourceuid from WH_Virgin.Derived.Customer_DuplicateSourceUID )
					--and cu.PostalSector in (select distinct dtm.fromsector 
					--	from WH_Virgin.relational.DriveTimeMatrix as dtm with (NOLOCK)
						--where dtm.tosector IN (select distinct substring([PostCode],1,charindex(' ',[PostCode],1)+1) 
						--									 from WH_Virgin.relational.outlet
						--									 WHERE 	partnerid = 4265)--adjust to outlet)
						--									 AND dtm.DriveTimeMins <= 20)
				group by CL.CINID, cu.FanID
			) CL

left Join	(	Select		ct.CINID
							
							, count(1) as trans 

									
								
				From		WH_Virgin.Trans.ConsumerTransaction ct with (nolock)
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



	IF OBJECT_ID('sandbox.vernon.VM_Lait_single_trans_150420') IS NOT NULL DROP TABLE sandbox.vernon.VM_Lait_single_trans_150420

	select	 CINID
			, fanid
	into	sandbox.vernon.VM_Lait_single_trans_150420
	from	#Final

	
	IF OBJECT_ID('tempdb..#PreSelection') IS NOT NULL DROP TABLE #PreSelection
	SELECT	FanID
	INTO #PreSelection
	FROM (	SELECT FanID
			FROM [Sandbox].[Vernon].[VM_Lait_single_trans_150420]
			UNION
			SELECT	sg.FanID
			FROM [Segmentation].[Roc_Shopper_Segment_Members] sg
			WHERE PartnerID = 4721
			AND EndDate IS NULL
			AND ShopperSegmentTypeID IN (7, 8)) sIf Object_ID('WH_Virgin.Selections.LW081_PreSelection') Is Not Null Drop Table WH_Virgin.Selections.LW081_PreSelectionSelect FanIDInto WH_Virgin.Selections.LW081_PreSelectionFROM  #PRESELECTIONEND