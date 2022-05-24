
CREATE PROCEDURE [Selections].[NB014_PreSelection_sProc]
AS
BEGIN

IF OBJECT_ID('TEMPDB..#DISTINCT_HOUSEHOLDS') IS NOT NULL DROP TABLE #DISTINCT_HOUSEHOLDS
SELECT DISTINCT HouseholdID 
 , BankAccountID
INTO #DISTINCT_HOUSEHOLDS
FROM Warehouse.Relational.MFDD_Households
CREATE CLUSTERED INDEX CIX_CC ON #DISTINCT_HOUSEHOLDS(BankAccountID)


IF OBJECT_ID('TEMPDB..#CC_Sky') IS NOT NULL DROP TABLE #CC_Sky
SELECT ConsumerCombinationID_DD
INTO #CC_Sky
FROM Warehouse.Relational.ConsumerCombination_DD CC
WHERE BrandID = 395
CREATE CLUSTERED INDEX CIX_CC ON #CC_Sky(ConsumerCombinationID_DD)

DECLARE @DATE_3 DATE = DATEADD(MONTH, -3, GETDATE())

IF OBJECT_ID('TEMPDB..#SKY_SHOPPERS') IS NOT NULL DROP TABLE #SKY_SHOPPERS
SELECT HouseholdID
 , CT.BankAccountID
 , SALES
INTO #SKY_SHOPPERS
FROM (
 SELECT CC.ConsumerCombinationID_DD
 , BankAccountID
 , SUM(CT.Amount) AS SALES
 FROM Warehouse.Relational.ConsumerTransaction_DD CT WITH(NOLOCK)
 JOIN #CC_Sky CC
 ON CT.ConsumerCombinationID_DD = CC.ConsumerCombinationID_DD
 WHERE TranDate >= @DATE_3
 GROUP BY CC.ConsumerCombinationID_DD
 , BankAccountID
 ) CT
JOIN #DISTINCT_HOUSEHOLDS D
 ON CT.BankAccountID = D.HouseholdID

IF OBJECT_ID('TEMPDB..#DISTINCT_HOUSEHOLD_2') IS NOT NULL DROP TABLE #DISTINCT_HOUSEHOLD_2
SELECT DISTINCT HouseholdID
 , SourceUID
INTO #DISTINCT_HOUSEHOLD_2
FROM Warehouse.Relational.MFDD_Households

IF OBJECT_ID('TEMPDB..#SKY_CUSTOMERS_L3M') IS NOT NULL DROP TABLE #SKY_CUSTOMERS_L3M
SELECT HouseholdID 
 , SourceUID
 , CINID
INTO #SKY_CUSTOMERS_L3M
FROM #DISTINCT_HOUSEHOLD_2 D
JOIN Warehouse.Relational.CINList CIN
 ON D.SourceUID = CIN.CIN
WHERE EXISTS (SELECT HouseholdID FROM #SKY_SHOPPERS S WHERE S.BankAccountID = D.HouseholdID GROUP BY HouseholdID)

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

DECLARE @DATE_2 DATE = DATEADD(MONTH, -2, GETDATE())
DECLARE @DATE_6 DATE = DATEADD(MONTH, -6, GETDATE())
DECLARE @DATE_14 DATE = DATEADD(MONTH, -14, GETDATE())
DECLARE @DATE_300 DATE = DATEADD(MONTH, -300, GETDATE())

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
										and TranDate > @DATE_2
 									then 1 else 0 end) as MainBrand_spender_2m
							, max(case when cc.brandid = @MainBrand
										and TranDate > @DATE_300
 									then 1 else 0 end) as MainBrand_spender_300m
							, max(case when cc.brandid = @MainBrand
										and TranDate > @DATE_14
 									then 1 else 0 end) as MainBrand_spender_14m
							, max(case when cc.brandid = @MainBrand
										and TranDate < @DATE_14 and TranDate > @DATE_300
 									then 1 else 0 end) as MainBrand_spender_300m_to_14m
																	
				From		Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
				Join		#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
				CROSS APPLY (
				 SELECT Excluded = CASE WHEN	cc.MID = '000000024420851' 
													and cc.MID = '000000024420771'
													and TranDate > @DATE_6 THEN 1 ELSE 0 END
							) x
				Where		0 < ct.Amount and x.Excluded = 0
							and TranDate > @DATE_300
				group by ct.CINID ) b
on	cl.CINID = b.CINID
Left Join 	#SKY_CUSTOMERS_L3M sand on cl.CINID = sand.CINID
where sand.CINID is null

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
IF OBJECT_ID('sandbox.SamW.NOWTV_TV_Broadband_110119_Acquire') IS NOT NULL 
	DROP TABLE sandbox.SamW.NOWTV_TV_Broadband_110119_Acquire

select	CINID
		, fanid
into sandbox.SamW.NOWTV_TV_Broadband_110119_Acquire
from	#segmentAssignment
where	MainBrand_spender_2m is null

IF OBJECT_ID('[Warehouse].[Selections].[NB014_PreSelection]') IS NOT NULL DROP TABLE [Warehouse].[Selections].[NB014_PreSelection]
SELECT	FanID
INTO [Warehouse].[Selections].[NB014_PreSelection]
FROM sandbox.SamW.NOWTV_TV_Broadband_110119_Acquire

END