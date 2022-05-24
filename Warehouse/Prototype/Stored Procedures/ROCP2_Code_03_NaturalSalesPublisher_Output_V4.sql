
/***************************************************************************
Author:	Main Code written by Jenny Hurley - SP Created by Suraj Chahal
Date: 25-01-2016
Purpose: ROC Phase 2 forecasting tool - Natural Sales Output By Publisher
***************************************************************************/
CREATE PROCEDURE [Prototype].[ROCP2_Code_03_NaturalSalesPublisher_Output_V4]
	(
	@IndividualBrand BIT
	)

AS
BEGIN

--DECLARE	@IndividualBrand BIT
--SET @IndividualBrand = 1
----------------------------------------------------------------------------------
----   Alogorithm 1 : RBS base (ex Myrewards) for NFi publishers
-----------------------------------------------------------------------------------

-- Cafe nero at brand level doesn't look right

delete from PROTOTYPE.ROCP2_PubScaling_BrandPubLevel
where brANDID = 75


---- The  segments excluding all base : assumes no triggers
IF OBJECT_ID ('tempdb..#OtherSegments') IS NOT NULL DROP TABLE #OtherSegments
SELECT	*
-- CREATING NULls so can use in coalesce when merging
	,CASE WHEN LOWVOL_NatSales IN ('LowVolume') THEN NULL ELSE RBS_RRo END AS RSB_RR 
	,CASE WHEN LOWVOL_NatSales IN ('LowVolume') THEN NULL ELSE RBS_SPSo END AS RBS_SPS
	,CASE WHEN LOWVOL_NatSales IN ('LowVolume') THEN NULL ELSE RBS_RR_Instoreo END AS RBS_RR_Instore
	,CASE WHEN LOWVOL_NatSales IN ('LowVolume') THEN NULL ELSE RBS_SPS_InStoreo END AS RBS_SPS_InStore
	,'AllBase' as AllSegments
into #OtherSegments
from 
	(
	SELECT	BrandID  
		,Segment
		,Timepoint
		,Counts
		,case when counts=0 then 'None in Segment' 
		when coalesce(avgw_spder,0)<25 then 'LowVolume' else '' END AS LOWVOL_NatSales -- Flag for low volume natural sales
		,case when Segment in ('Acquire') then 'Acquire'   
		when Segment in ('Grow','Retain') then 'Existing'
		when segment in ('Winback','WinbackPrime') then 'AllBase' -- didn't use Lapser here as didn;t validate well for halford.  With more investigate consider moving back to lapser
		when Segment in ('AllBase') then 'AllBase' else NULL END AS SegmentAgg
		,case when counts>0 then coalesce(avgw_spder,0)/ cast (counts as real) else 0 END AS RBS_RRo
		,case when avgw_spder>0 then coalesce(avgw_sales,0) / coalesce(avgw_spder,0) else 0 END AS RBS_SPSo
		,case when counts>0 then coalesce(avgw_spder_InStore,0)/ cast (counts as real) else 0 END AS RBS_RR_Instoreo
		,case when avgw_spder_InStore>0 then coalesce(avgw_sales_Instore,0) / coalesce(avgw_spder_InStore,0) else 0 END AS RBS_SPS_InStoreo
		,coalesce(avgw_spder,0) as avgw_spder
		,coalesce(avgw_sales,0) as avgw_sales
		,coalesce(avgw_Sales_InStore,0) as avgw_Sales_InStore
		,coalesce(avgw_spder_InStore,0) as avgw_spder_InStore
	FROM Prototype.[ROCP2_SegFore_RBSSeg_NaturalSales]
	WHERE Segment not in ('AllBase') 
	) a

--select * from #OtherSegments

IF OBJECT_ID ('tempdb..#OtherSegments_AGG') IS NOT NULL DROP TABLE #OtherSegments_AGG
SELECT	BrandID,
	SegmentAgg,
	Timepoint,
	LOWVOL_NatSales,
	avgw_spder,
	avgw_spder_Instore,
	case when LOWVOL_NatSales in ('LowVolume') then NULL else RBS_RRo END AS RSB_RR,
	case when LOWVOL_NatSales in ('LowVolume') then NULL else RBS_SPSo END AS RBS_SPS,
	case when LOWVOL_NatSales in ('LowVolume') then NULL else RBS_RR_Instoreo END AS RBS_RR_Instore,
	case when LOWVOL_NatSales in ('LowVolume') then NULL else RBS_SPS_InStoreo END AS RBS_SPS_InStore
INTO #OtherSegments_AGG
FROM	(
	select	BrandID  
		,Timepoint
		,SegmentAgg
		,SUM(COALESCE(counts,0)) as Counts
		,SUM(COALESCE(avgw_spder,0)) as avgw_spder
		,SUM(COALESCE(avgw_sales,0)) as avgw_sales
		,SUM(COALESCE(avgw_Sales_InStore,0)) as avgw_Sales_InStore
		,SUM(COALESCE(avgw_spder_InStore,0)) as avgw_spder_InStore
		,CASE WHEN SUM(COALESCE(counts,0))>0 then sum(coalesce(avgw_spder,0))/ cast (sum(coalesce(counts,0)) as real) else 0 END AS RBS_RRo
		,CASE WHEN SUM(COALESCE(avgw_spder,0))>0 then sum(coalesce(avgw_sales,0)) / sum(coalesce(avgw_spder,0)) else 0 END AS RBS_SPSo
		,CASE WHEN SUM(COALESCE(counts,0))>0 then sum(coalesce(avgw_spder_InStore,0))/ cast (sum(coalesce(counts,0))as real) else 0 END AS RBS_RR_Instoreo
		,CASE WHEN SUM(COALESCE(avgw_spder_InStore,0))>0 then sum(coalesce(avgw_sales_Instore,0)) / sum(coalesce(avgw_spder_InStore,0)) else 0 END AS RBS_SPS_InStoreo
		,CASE WHEN SUM(COALESCE(counts,0))=0 then 'None in Segment' 
		when sum(coalesce(avgw_spder,0))<25 then 'LowVolume' else '' END AS LOWVOL_NatSales -- Flag for low volume natural sales
	from #OtherSegments
	group by BrandID, Timepoint, SegmentAgg
	)a

--select * from #OtherSegments_AGG

IF OBJECT_ID ('tempdb..#AllBaseSegments') IS NOT NULL DROP TABLE #AllBaseSegments
SELECT	BrandID,
	'AllBase' as Allsegment,
	Timepoint,
	Counts,
	case when counts=0 then 'None in Segment' when coalesce(avgw_spder,0)<25 then 'LowVolume' else '' END AS LOWVOL_NatSales,
	case when counts>0 then coalesce(avgw_spder,0)/ cast (counts as real) else 0 END AS RBS_RR,
	case when avgw_spder>0 then coalesce(avgw_sales,0) / coalesce(avgw_spder,0) else 0 END AS RBS_SPS,
	case when counts>0 then coalesce(avgw_spder_InStore,0)/ cast (counts as real) else 0 END AS RBS_RR_Instore,
	case when avgw_spder_InStore>0 then coalesce(avgw_sales_Instore,0) / coalesce(avgw_spder_InStore,0) else 0 END AS RBS_SPS_InStore,
	AVGw_Spder,
	AVGw_Sales,
	AVGw_Spder_Instore
INTO #AllBaseSegments
FROM Prototype.ROCP2_SegFore_RBSSeg_NaturalSales
WHERE Segment in ('AllBase')


--- Replacing low volume segments with all base..all base with the 
--- Replacing only the low volume segments which in some cases might cause a funny pattern in expected results... however it might be more accurate if not all
--segments are forecast

IF OBJECT_ID ('tempdb..#Outputs0') IS NOT NULL DROP TABLE #Outputs0
SELECT	s.BrandID,
	s.Segment,
	s.segmentagg,
	s.Timepoint,
	s.counts,
	s.LOWVOL_NatSales as Orig_Flg,
	s.avgw_spder as OrigSeg_vol,
	sa.avgw_spder as SegAgg_vol,
	sa.LOWVOL_NatSales as SegAgg_Flg,
	ab.avgw_spder as AllBase_vol,
	ab.LOWVOL_NatSales as AllBase_Flg,
	COALESCE(s.RBS_SPS,sa.RBS_SPS,ab.RBS_SPS) as RBS_SPS,
	COALESCE(s.RSB_RR,sa.RSB_RR,ab.RBS_RR) as RBS_RR,
	COALESCE(s.RBS_RR_Instore,sa.RBS_RR_Instore,ab.RBS_RR_Instore) as RBS_RR_Instore,
	COALESCE(s.RBS_SPS_Instore,sa.RBS_SPS_Instore,ab.RBS_SPS_Instore) as RBS_SPS_Instore,
	COALESCE(s.avgw_spder,sa.avgw_spder,ab.avgw_spder) as avgw_spder,
	COALESCE(s.avgw_spder_Instore,sa.avgw_spder_Instore,ab.avgw_spder_Instore) as avgw_spder_Instore
INTO #Outputs0
FROM #OtherSegments s
LEFT JOIN #OtherSegments_AGG sa
	ON sa.Timepoint = s.Timepoint
	AND s.SegmentAgg = sa.SegmentAgg
	AND s.BrandID = sa.BrandID
LEFT JOIN #AllBaseSegments ab
	ON ab.Timepoint = s.Timepoint
	AND ab.BrandID = s.BrandID
	AND ab.Allsegment = s.AllSegments


IF OBJECT_ID ('tempdb..#Outputs') IS NOT NULL DROP TABLE #Outputs
SELECT *
INTO #Outputs 
FROM	(
	SELECT	p.Publisher,
		b.*
	FROM #outputs0 b
	CROSS JOIN Prototype.ROCP2_PublisherList p
	WHERE p.Type1 in ('A1_NFi1')
UNION ALL
	SELECT	p.Publisher,
		b.BrandID,
		Allsegment as Segment,
		'AllBase' as SegmentAgg,
		Timepoint,
		Counts,
		LOWVOL_NatSales as Orig_flg,
		AVGw_spder as OrigSeg_vol,
		AVGw_spder as SegAgg_vol,
		LOWVOL_NatSales as SegAgg_Flg,
		AVGw_spder as AllBase_vol,
		LOWVOL_NatSales as AlLBase_Flg,
		RBS_SPS,
		RBS_RR,
		RBS_RR_Instore,
		RBS_SPS_Instore,
		AVGw_spder,
		AVGw_spder_InStore
	FROM  #AllBaseSegments b
	CROSS JOIN Prototype.ROCP2_PublisherList p
	WHERE p.Type1 in ('A1_NFi1')
	)a


--select * from Prototype.ROCP2_PubScaling_BrandPubLevel

--select * from Prototype.ROCP2_PubScaling_BrandPubLevel where partnername like ('Halfords%')

IF OBJECT_ID ('tempdb..#Outputs2') IS NOT NULL DROP TABLE #Outputs2
SELECT	b.*,
	pb.ScalingRR as ScalingRR_PB,
	gp.ScalingRR as ScalingRR_Gp
	,coalesce(pb.ScalingRR, gp.ScalingRR  , 1) as RRScale
INTO #Outputs2
FROM #Outputs b
LEFT JOIN Prototype.ROCP2_PubScaling_BrandPubLevel pb 
	ON b.Publisher = pb.clubname
	AND pb.BrandID = b.BrandID
	AND b.SegmentAgg = pb.segmentAgg
LEFT JOIN Prototype.ROCP2_PubScaling_GenericPub gp 
	ON b.Publisher = gp.clubname
	AND b.SegmentAgg = gp.segmentAgg

-- SELECT * FROM #Outputs2 WHERE BRANDID= 75
/********************************************************************/
IF OBJECT_ID ('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
CREATE TABLE #Brand
	(
	BrandID SMALLINT NOT NULL,
	BrandName VARCHAR(75) NULL,
	Sector SMALLINT,
	AcquireL0 SMALLINT,
	LapserL0 SMALLINT,
	RowNo SMALLINT,
	AcquireL SMALLINT,
	LapserL SMALLINT
	PRIMARY KEY (BrandID)
	)

-------------------------------------
DECLARE @base INT
SET @base = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)
DECLARE @baser INT
SET @baser = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

-------------------------------------
IF @IndividualBrand <> 0
BEGIN

INSERT INTO #Brand
SELECT	*
FROM Prototype.ROCP2_Brandlist_Individual
--

DELETE FROM Prototype.ROCP2_NaturalSalesPub_FinalOutput
WHERE BrandID IN (SELECT BrandID FROM #Brand)


--DECLARE @base INT
--SET @base = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

INSERT INTO Prototype.ROCP2_NaturalSalesPub_FinalOutput
SELECT	b.BrandName,
	b.BrandID,
	Publisher,
	Timepoint,
	Segment,
	Counts / cast (@base as real) as Perbase,
	RBS_RR * RRScale as RR,
	RBS_SPS as SPS,
	coalesce(avgw_spder,0) as avgw_spder,
	RBS_SPS* (RBS_RR * RRScale) as SPC,
	RBS_RR_Instore*RRScale as   RR_Instore,
	RBS_SPS_InStore as SPS_Instore,
	coalesce(avgw_spder_Instore,0) as avgw_spder_Instore,
	RBS_SPS_InStore* RBS_RR_Instore*RRScale  as SPC_Instore,
	RRScale,
	RBS_RR,
	RBS_RR_Instore
FROM #Outputs2 o
INNER JOIN #Brand b
	ON b.BrandID = o.BrandID

--DECLARE @baser INT
--SET @baser = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

IF OBJECT_ID ('tempdb..#A2_Publisherouts1') IS NOT NULL DROP TABLE #A2_Publisherouts1
select b.brandname
      ,b.brandID
	  ,p.Publisher
	  ,Timepoint
	  ,Segment
	  ,Counts / cast (@baser as real) as Perbase
	  ,Avgw_Spder / cast (Counts as real) as RR
	  ,case when Avgw_Spder>0 then Avgw_Sales / Avgw_Spder else NULL end as SPS
	  ,coalesce(avgw_spder,0) as avgw_spder
	  ,case when AVGw_Spder>0 then AVGw_Sales/cast (Counts as real) else NULL end as SPC
	  ,Avgw_Spder_Instore / cast (Counts as real) as   RR_Instore
	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore / AVGw_Spder_InStore else NULL end as SPS_Instore
	  ,coalesce(avgw_spder_Instore,0) as avgw_spder_Instore
	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore/AVGw_Spder_InStore else NULL end   as SPC_Instore
	  ,1 as RRScale
	  ,Avgw_Spder / cast (Counts as real)  as RBS_RR   -- Same as above but populating to try and avoid confusion
	  ,Avgw_Spder_Instore / cast (Counts as real) as RBS_RR_Instore
into #A2_Publisherouts1
from Prototype.ROCP2_SegFore_Fi_NaturalSales s
inner join #brand b on b.BrandID=s.BrandID
cross join prototype.ROCP2_PublisherList p 
where p.type1 in ('A2_Fi1')

INSERT INTO Prototype.ROCP2_NaturalSalesPub_FinalOutput
select * from #A2_Publisherouts1


END
ELSE
BEGIN

TRUNCATE TABLE Prototype.ROCP2_NaturalSalesPub_FinalOutput
--DECLARE @base INT
--SET @base = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

INSERT INTO Prototype.ROCP2_NaturalSalesPub_FinalOutput
SELECT	b.BrandName,
	b.BrandID,
	Publisher,
	Timepoint,
	Segment,
	Counts / cast (@base as real) as Perbase,
	RBS_RR * RRScale as RR,
	RBS_SPS as SPS,
	coalesce(avgw_spder,0) as avgw_spder,
	RBS_SPS* (RBS_RR * RRScale) as SPC,
	RBS_RR_Instore*RRScale as   RR_Instore,
	RBS_SPS_InStore as SPS_Instore,
	coalesce(avgw_spder_Instore,0) as avgw_spder_Instore,
	RBS_SPS_InStore* RBS_RR_Instore*RRScale  as SPC_Instore,
	RRScale,
	RBS_RR,
	RBS_RR_Instore
FROM #Outputs2 o
INNER JOIN Relational.Brand b
	ON b.BrandID = o.BrandID

--DECLARE @baser INT
--SET @baser = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

IF OBJECT_ID ('tempdb..#A2_Publisherouts2') IS NOT NULL DROP TABLE #A2_Publisherouts2
select b.brandname
      ,b.brandID
	  ,p.Publisher
	  ,Timepoint
	  ,Segment
	  ,Counts / cast (@baser as real) as Perbase
	  ,Avgw_Spder / cast (Counts as real) as RR
	  ,case when Avgw_Spder>0 then Avgw_Sales / Avgw_Spder else NULL end as SPS
	  ,coalesce(avgw_spder,0) as avgw_spder
	  ,case when AVGw_Spder>0 then AVGw_Sales/cast (Counts as real) else NULL end as SPC
	  ,Avgw_Spder_Instore / cast (Counts as real) as   RR_Instore
	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore / AVGw_Spder_InStore else NULL end as SPS_Instore
	  ,coalesce(avgw_spder_Instore,0) as avgw_spder_Instore
	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore/AVGw_Spder_InStore else NULL end   as SPC_Instore
	  ,1 as RRScale
	  ,Avgw_Spder / cast (Counts as real)  as RBS_RR   -- Same as above but populating to try and avoid confusion
	  ,Avgw_Spder_Instore / cast (Counts as real) as RBS_RR_Instore
into #A2_Publisherouts2
from Prototype.ROCP2_SegFore_Fi_NaturalSales s
inner join relational.brand b on b.BrandID=s.BrandID
cross join prototype.ROCP2_PublisherList p 
where p.type1 in ('A2_Fi1')


INSERT INTO Prototype.ROCP2_NaturalSalesPub_FinalOutput
select * from #A2_Publisherouts2

END

/**************************************************************************/
/**     Creating the outputs for the RBS base data                        */
/**************************************************************************/

--select top 100 * from Prototype.ROCP2_NaturalSalesPub_FinalOutput
--select top 100 * from Prototype.ROCP2_SegFore_Fi_NaturalSales
--- Taking raw data ... no low volume adjustments at the moment. Time very tight and need to get to the end of the process. 
-- NO SCALING AS MYREWARDS BASE 
--DECLARE @baser INT
--SET @baser = (SELECT COUNT(DISTINCT CINID) FROM Prototype.ROCP2_SegFore_FixedBase)

--IF OBJECT_ID ('tempdb..#A2_Publisherouts') IS NOT NULL DROP TABLE #A2_Publisherouts
--select b.brandname
--      ,b.brandID
--	  ,p.Publisher
--	  ,Timepoint
--	  ,Segment
--	  ,Counts / cast (@baser as real) as Perbase
--	  ,Avgw_Spder / cast (Counts as real) as RR
--	  ,case when Avgw_Spder>0 then Avgw_Sales / Avgw_Spder else NULL end as SPS
--	  ,coalesce(avgw_spder,0) as avgw_spder
--	  ,case when AVGw_Spder>0 then AVGw_Sales/cast (Counts as real) else NULL end as SPC
--	  ,Avgw_Spder_Instore / cast (Counts as real) as   RR_Instore
--	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore / AVGw_Spder_InStore else NULL end as SPS_Instore
--	  ,coalesce(avgw_spder_Instore,0) as avgw_spder_Instore
--	  ,case when AVGw_Spder_InStore>0 then AVGw_Sales_InStore/AVGw_Spder_InStore else NULL end   as SPC_Instore
--	  ,1 as RRScale
--	  ,Avgw_Spder / cast (Counts as real)  as RBS_RR   -- Same as above but populating to try and avoid confusion
--	  ,Avgw_Spder_Instore / cast (Counts as real) as RBS_RR_Instore
--into #A2_Publisherouts
--from Prototype.ROCP2_SegFore_Fi_NaturalSales s
--inner join relational.brand b on b.BrandID=s.BrandID
--cross join prototype.ROCP2_PublisherList p 
--where p.type1 in ('A2_Fi1')




/*********************************************************************************/
---- Inserting the RBS publisher type into outputs
/********************************************************************************/

--INSERT INTO Prototype.ROCP2_NaturalSalesPub_FinalOutput
--select * from #A2_Publisherouts

--select * from Prototype.ROCP2_NaturalSalesPub_FinalOutput where brandid = 1556


-------------------------------------------------------------------------------------------------------------
------   Low Volumes
-- Low by Segment or Low for whole base 
-- Defining low volume :  Either as 0 forecast values or should I also define as those where average spder is low
--- Currently defined low 0 but could adjust this to be less than 5
------------------------------------------------------------------------------

--- If any of the segments has a low volume then replace

IF OBJECT_ID('tempdb..#NoDataBrands') IS NOT NULL DROP TABLE #NoDataBrands
select distinct brandid
,1 as NoData
into #NoDataBrands
from  Prototype.ROCP2_NaturalSalesPub_FinalOutput
where Segment = 'AllBase'
		and avgw_spder = 0 or avgw_spder is null

--select * from #NoDataBrands

 --(avgw_spder is NULL)
--and CustomerType = 'Emailbase'

--select * from Warehouse.InsightArchive.STOSalesforecast_NaturalSales where brandid = 1556

-- select * from #NoDataBrands

IF OBJECT_ID('tempdb..#NoSegmentBrand') IS NOT NULL DROP TABLE #NoSegmentBrand
select distinct ns.brandID
into #NoSegmentBrand
from  Prototype.ROCP2_NaturalSalesPub_FinalOutput ns
left join #NoDataBrands nd on nd.brandid=ns.brandid
where avgw_spder = 0 and Perbase > 0 ---avgw_spder is NULL
and Nodata is null -- Only getting brands where no segments in part of segments (ie. some data in the all emailbase)

--select * from #NoSegmentBrand

---- Building generic RRs and SPC
--IF OBJECT_ID('tempdb..#GenericAcquire_All') IS NOT NULL DROP TABLE #GenericAcquire_All
--select brandID 
-- ,max(case when CustomerType='Emailbase' then avgw_sales/cast(counts as real) else NULL end) as Allbase_SPC
--,max(case when CustomerType='Emailbase' then avgw_spder/cast(counts as real) else NULL end) as Allbase_RR

--,max(case when CustomerType='Acquire' then avgw_sales/cast(counts as real) else NULL end) as Acqu_SPC
--,max(case when CustomerType='Acquire' then avgw_spder/cast(counts as real) else NULL end) as Acqu_RR
--into #GenericAcquire_All
--from Warehouse.InsightArchive.STOSalesforecast_NaturalSales
----where brandid in (select distinct brandid from #NoSegmentBrand)
--group by brandid



--select * from Warehouse.InsightArchive.STOSalesforecast_NaturalSales where brandid=1010
--select * from #GenericAcquire_All  where brandid=1010

IF OBJECT_ID('tempdb..#TotBrand_Estimates') IS NOT NULL DROP TABLE #TotBrand_Estimates
select brandid
      , SpendThisYear / cast (TotalCustomerCountThisYear as real) / 52 as TBS_Avgw_SPC
      , CustomerCountThisYear / cast (TotalCustomerCountThisYear as real) /52  as TBS_Avgw_RR
      , (SpendThisYear-OnlineSpendThisYear) / cast ((TotalCustomerCountThisYear-TotalOnlineCustomerCountThisYear) as real)/ 52 as TBS_Avgw_SPC_Instore
      , (CustomerCountThisYear-OnlineCustomerCountThisYear) / cast (TotalCustomerCountThisYear-TotalOnlineCustomerCountThisYear as real) /52  as TBS_Avgw_RR_InStore
into #TotBrand_Estimates
from  warehouse.mi.TotalBrandSpend_CBP 
 cross join  warehouse.mi.GrandTotalCustomers_CBP 

--select * from #TotBrand_Estimates where brandid=1784

--select * from warehouse.mi.TotalBrandSpend
--select * from warehouse.mi.GrandTotalCustomers_CBP

--IF OBJECT_ID('tempdb..#STOSalesforecast_NaturalSales_Summary') IS NOT NULL DROP TABLE #STOSalesforecast_NaturalSales_Summary

--select *
--,avgw_sales/cast(counts as real) as SPC_base
--,avgw_spder/cast(counts as real) as RR_base
--into #STOSalesforecast_NaturalSales_Summary
--from Warehouse.InsightArchive.STOSalesforecast_NaturalSales


-------------------------------------------------------------------------------
-----  Additional cals and tidy for output
--------------------------------------------------------------------------------

-- What would I do if the build weeks included Xmas?  It's ok as long as the adjustment considers them!
-- WHAT TO DO WITH NULL SPEND FOR GROUPS! -- Give the overall? Could do this for low volumes in general! 
--- Could be issues with low response and seasonal scaling?  


IF OBJECT_ID('tempdb..#brandfixes') IS NOT NULL DROP TABLE #brandfixes
select		BrandName
			,a.BrandID
			,Publisher
			,Timepoint
			, Segment
			,Perbase
			,b.TBS_Avgw_RR as RR
			,case when b.TBS_Avgw_RR = 0 then 0 else b.TBS_Avgw_SPC/b.TBS_Avgw_RR end as SPS
			,avgw_spder
			,b.TBS_Avgw_SPC as SPC
			,b.TBS_Avgw_RR_InStore as RR_Instore
			,case when b.TBS_Avgw_RR_Instore = 0 then 0 else b.TBS_Avgw_SPC_Instore/b.TBS_Avgw_RR_Instore end as  RBS_SPS_InStore
			,avgw_spder_Instore
			,b.TBS_Avgw_SPC_Instore as SPC_Instore
			,a.RRScale
			,a.RBS_RR
			,a.RBS_RR_Instore
into		#brandfixes
from		Prototype.ROCP2_NaturalSalesPub_FinalOutput a
left join	#TotBrand_Estimates b on a.BrandID = b.BrandID
where	Perbase > 0
		and (avgw_spder = 0 or avgw_spder is null)
		and (spc = 0 or SPC is null)


delete from Prototype.ROCP2_NaturalSalesPub_FinalOutput
where	Perbase > 0
		and (avgw_spder = 0 or avgw_spder is null)
		and (spc = 0 or SPC is null)


IF OBJECT_ID('Prototype.ROCP2_NaturalSalesPub_FinalOutput2') IS NOT NULL DROP TABLE Prototype.ROCP2_NaturalSalesPub_FinalOutput2
select		*
into		Prototype.ROCP2_NaturalSalesPub_FinalOutput2
from		Prototype.ROCP2_NaturalSalesPub_FinalOutput
union 
select		*
from		#brandfixes

--select * from Prototype.ROCP2_NaturalSalesPub_FinalOutput2 where brandid = 1784






/**************************************************************************/

--select 'Paste into Data NaturalSales Cell B9'

INSERT INTO Prototype.ROCP2_AssessmentBrands
SELECT	bli.BrandID
FROM Prototype.ROCP2_BrandList_Individual bli
LEFT OUTER JOIN Prototype.ROCP2_AssessmentBrands ab
	ON bli.BrandID = ab.BrandID
WHERE ab.BrandID IS NULL



END

