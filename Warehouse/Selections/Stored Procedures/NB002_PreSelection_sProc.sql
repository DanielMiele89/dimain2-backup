-- =============================================-- Author:  <Rory Francis>-- Create date: <2019-09-06>-- Description: < sProc to run preselection code per camapign >-- =============================================CREATE Procedure [Selections].[NB002_PreSelection_sProc]ASBEGIN
IF OBJECT_ID('tempdb..#CCD') IS NOT NULL DROP TABLE #CCD
SELECT *
INTO #CCD
FROM Relational.ConsumerCombination_DD
WHERE BrandID = 395

CREATE CLUSTERED INDEX CIX_CC on #CCD (ConsumerCombinationID_DD)

-- Count the DDpayments in the respective period
DECLARE @Today DATE = GETDATE()
DECLARE @ThreeMonthsAgo DATE = DATEADD(month, -3, @Today)

IF OBJECT_ID('tempdb..#CT') IS NOT NULL DROP TABLE #CT
SELECT DISTINCT
	   BankAccountID
	 , FanID
INTO #CT
FROM Relational.ConsumerTransaction_DD ct
WHERE ct.TranDate >= @ThreeMonthsAgo
AND EXISTS (SELECT 1
			FROM #CCD cc
			WHERE ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD)

IF OBJECT_ID('tempdb..#MFDD_Households') IS NOT NULL DROP TABLE #MFDD_Households
SELECT DISTINCT FanID
INTO #MFDD_Households
FROM Relational.MFDD_Households hh
WHERE EXISTS (SELECT 1 FROM #CT ct WHERE hh.FanID = ct.FanID)
AND EndDate IS NULL
UNION
SELECT DISTINCT FanID
FROM Relational.MFDD_Households hh
WHERE EXISTS (SELECT 1 FROM #CT ct WHERE hh.BankAccountID = ct.BankAccountID)
AND EndDate IS NULL

CREATE CLUSTERED INDEX CIX_FanID on #MFDD_Households (FanID)



IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
Select	 br.BrandID
		, br.BrandName
		, cc.ConsumerCombinationID
		, MID
Into	#CC
From	Warehouse.Relational.Brand br
Join	Warehouse.Relational.ConsumerCombination cc
	on	br.BrandID = cc.BrandID
Where	br.BrandID in (2626) -- 2626 or 1809
Order By br.BrandName
CREATE CLUSTERED INDEX ix_ComboID ON #cc(ConsumerCombinationID)


--if needed to do SoW
Declare @MainBrand smallint = 2626	 -- Main Brand	

--		Assign Shopper segments
If Object_ID('tempdb..#segmentAssignment') IS NOT NULL DROP TABLE #segmentAssignment
Select	 cl.CINID			-- keep CINID and FANID
		, cl.fanid			-- only need these two fields for forecasting / targetting everything else is dependant on requirements
		, MainBrand_spender_2m
		, MainBrand_spender_14m
		, MainBrand_spender_300m
		, MainBrand_spender_300m_to_14m
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
							, sum(ct.Amount) as sales
							, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(month,-2,getdate())
 									then 1 else 0 end) as MainBrand_spender_2m
							, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(month,-300,getdate())
 									then 1 else 0 end) as MainBrand_spender_300m
							, max(case when cc.brandid = @MainBrand
										and TranDate > dateadd(month,-14,getdate())
 									then 1 else 0 end) as MainBrand_spender_14m
							, max(case when cc.brandid = @MainBrand
										and TranDate < dateadd(month,-14,getdate()) and TranDate > dateadd(month,-300,getdate())
 									then 1 else 0 end) as MainBrand_spender_300m_to_14m
																	
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				CROSS APPLY (
				 SELECT Excluded = CASE WHEN	cc.MID = '000000024420851' 
													and cc.MID = '000000024420771'
													and TranDate > dateadd(month,-6,getdate()) THEN 1 ELSE 0 END
							) x
				Where		0 < ct.Amount and x.Excluded = 0
							and TranDate > dateadd(month,-300,getdate())
				group by ct.CINID ) b
on	cl.CINID = b.CINID
WHERE NOT EXISTS (SELECT 1 FROM #MFDD_Households hh WHERE cl.FanID = hh.FanID)


--select count(1), MainBrand_spender_2m
--		, MainBrand_spender_14m
--		, MainBrand_spender_300m
--		, MainBrand_spender_300m_to_14m
--from #segmentAssignment
----where MainBrand_spender_2m = 0
--group by MainBrand_spender_2m
--		, MainBrand_spender_14m
--		, MainBrand_spender_300m
--		, MainBrand_spender_300m_to_14m


-- Selection codes
-- 2770594
IF OBJECT_ID('sandbox.Conal.NOWTV_TV_Broadband_110119_Acquire') IS NOT NULL 
	DROP TABLE sandbox.Conal.NOWTV_TV_Broadband_110119_Acquire

select	CINID
		, fanid
into sandbox.Conal.NOWTV_TV_Broadband_110119_Acquire
from	#segmentAssignment
where	MainBrand_spender_2m is nullIf Object_ID('Warehouse.Selections.NB002_PreSelection') Is Not Null Drop Table Warehouse.Selections.NB002_PreSelectionSelect FanIDInto Warehouse.Selections.NB002_PreSelectionFrom #segmentAssignmentEND