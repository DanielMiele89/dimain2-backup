CREATE PROCEDURE Prototype.SH_DataBrand 
AS
BEGIN
	SET NOCOUNT ON;

    -- Produce masterretailerfile
	IF OBJECT_ID('tempdb..#masterretailerfile') IS NOT NULL DROP TABLE #masterretailerfile
	SELECT BrandID
			,BrandName
		  ,[SS_AcquireLength]
		  ,[SS_LapsersDefinition]
		  ,[SS_WelcomeEmail]
		  ,cast(SS_Acq_Split*100 as int) as Acquire_Pct
	INTO #masterretailerfile
	FROM [Warehouse].[Relational].[MRF_ShopperSegmentDetails] a
	  inner join warehouse.Relational.Partner p on a.PartnerID = p.PartnerID

	--SELECT
	--'Copy results to columns A in sheet DatabrandandPub -' ---Instructions

	-- Select output
	select distinct a.BrandName
	 ,a.BrandID
	,coalesce(mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0) as AcquireL
	,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0) as LapserL
	,a.sectorID
	,COALESCE(mrf.Acquire_Pct,blk.Acquire_Pct,Acquire_Pct0) as Acquire_Pct
	from (
	select ab.BrandID
		  ,b.BrandName
		  ,b.sectorID
		  ,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
		  ,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
		  ,lk.Acquire_Pct as Acquire_Pct0
	from warehouse.Prototype.ROCP2_AssessmentBrands ab
	inner join warehouse.relational.brand b on ab.BrandID=b.BrandID
	left join Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on lk.sectorid=b.sectorID ) a
	left join warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on blk.brandid=a.brandID
	LEFT JOIN #masterretailerfile mrf on mrf.BrandID = a.BrandID
	where coalesce(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null
END
