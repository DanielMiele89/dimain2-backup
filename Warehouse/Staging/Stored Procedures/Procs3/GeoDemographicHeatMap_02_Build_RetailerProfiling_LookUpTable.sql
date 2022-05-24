﻿

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 11/12/2014
-- Description: This query is an adaptation of the Profiling Query provided by LG.
--		This creates the retailer look up table to be linked to to find a
--		customer's likeliness to shop.
-- *******************************************************************************
CREATE PROCEDURE [Staging].[GeoDemographicHeatMap_02_Build_RetailerProfiling_LookUpTable] 
	WITH EXECUTE AS OWNER		
AS
BEGIN
	SET NOCOUNT ON;

/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_02_Build_RetailerProfiling_LookUpTable',
	TableSchemaName = 'Relational',
	TableName = 'GeoDemographicHeatMap_LookUp_Table',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

	

/*****************************************************************
*********************Finding Live Partners************************
*****************************************************************/
IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
SELECT	ROW_NUMBER() OVER(ORDER BY a.PartnerID) as RowNo,
	a.PartnerID,
	p.BrandID,
	p.PartnerName,
	p.BrandName
INTO #Brands
FROM Warehouse.Relational.Partner_CBPDates a
INNER JOIN Warehouse.Relational.Partner p
	on a.PartnerID = p.PartnerID
WHERE	GETDATE() <= COALESCE(DATEADD(MM,5,Scheme_EndDate),GETDATE())
--(32 row(s) affected)
CREATE CLUSTERED INDEX IDX_BrandID ON #Brands (BrandID)


/*****************************************************************
********************Identify CCID's of Partners*******************
*****************************************************************/
IF OBJECT_ID('tempdb..#BrandCCIDs') IS NOT NULL DROP TABLE #BrandCCIDs
SELECT	b.PartnerID,
	cc.ConsumerCombinationID
INTO #BrandCCIDs
FROM Warehouse.Relational.ConsumerCombination cc (NOLOCK)
INNER JOIN #Brands b
	ON b.BrandID = cc.BrandID

CREATE CLUSTERED INDEX IDX_CCID ON #BrandCCIDs (ConsumerCombinationID)
CREATE NONCLUSTERED INDEX IDX_PartnerID ON #BrandCCIDs (PartnerID)


/*****************************************************************
*******************CREATE GeoDem Summary Table********************
*****************************************************************/
IF OBJECT_ID('tempdb..#GeoDemSummary') IS NOT NULL DROP TABLE #GeoDemSummary
SELECT	fp.PartnerID,
	b.BrandID,
	b.brandname,
	DriveTimeBand,
	Gender,
	AgeGroup,
	CAMEO_CODE_GRP,
	COUNT(DISTINCT FanID) as CardHolders	
INTO #GeoDemSummary
FROM Warehouse.Staging.WRF_654_FinalReferenceTable fp
INNER JOIN #Brands b 
	on fp.PartnerID = b.PartnerID
GROUP BY fp.PartnerID,b.BrandID,b.brandname,DriveTimeBand,Gender,AgeGroup,CAMEO_CODE_GRP

CREATE CLUSTERED INDEX IDX_PID ON #GeoDemSummary (PartnerID)


--SELECT	*
--FROM #GeoDemSummary
--ORDER BY PartnerID, DriveTimeBand,Gender,AgeGroup,CAMEO_CODE_grp
/*****************************************************************
************Transactional Behaviour in last 12 months*************
*****************************************************************/
--Find Customer CINs
IF OBJECT_ID ('tempdb..#FanCINIDs') IS NOT NULL DROP TABLE #FanCINIDs
SELECT	DISTINCT
	c.FanID,
	cl.CINID
INTO #FanCINIDs
FROM Warehouse.Relational.Customer c
INNER JOIN Warehouse.Relational.CINList cl
	ON c.SourceUID = cl.CIN
WHERE	c.CurrentlyActive = 1

CREATE CLUSTERED INDEX IDX_CIN ON #FanCINIDs (CINID)
CREATE NONCLUSTERED INDEX IDX_Fan ON #FanCINIDs (FanID)


IF OBJECT_ID('tempdb..#DataTY') IS NOT NULL DROP TABLE #DataTY
CREATE TABLE #DataTY
	(
	FanID INT NOT NULL,
	PartnerID INT NOT NULL,
	Trans INT,
	Spend NUMERIC(32,2)
	)

--Declare Date Values
DECLARE @StartDate DATE,
	@EndDate DATE,
	@StartRow INT,
	@PartnerID INT

SET @StartDate = (SELECT StartDate FROM Warehouse.Relational.CustomerAttributeDates)
SET @EndDate = (SELECT EndDate FROM Warehouse.Relational.CustomerAttributeDates)	
SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM #Brands)

BEGIN

	--Find Transactional Spend in the Last Year
	INSERT INTO #DataTY
	SELECT	fc.FanID, 
		cc.PartnerID,
		COUNT(1) as Trans,
		SUM(Amount) as Spend
	FROM Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
	INNER JOIN #FanCINIDs fc
		ON ct.CINID = fc.CINID
	INNER JOIN Warehouse.Staging.WRF_654_FanPartner fp 
		ON fc.FanID = fp.FanID
	INNER JOIN #BrandCCIDs cc 
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		AND cc.PartnerID = fp.PartnerID
		AND fp.PartnerID = cc.PartnerID
	WHERE	Amount > 0 
		AND ct.TranDate BETWEEN @StartDate AND @EndDate
		AND cc.PartnerID = @PartnerID
	GROUP BY fc.FanID, cc.PartnerID

	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow)

END

CREATE INDEX IDX_PartnerID ON #DataTY (PartnerID)
CREATE CLUSTERED INDEX IDX_FanID ON #DataTY (FanID)


/*****************************************************************
***************Creating the Brand Variables Table*****************
*****************************************************************/
IF OBJECT_ID('tempdb..#BrandVariables') IS NOT NULL DROP TABLE #BrandVariables
SELECT	frt.PartnerID,
	Gender,
	AgeGroup,
	CAMEO_CODE_Grp,
	DriveTimeBand,
	SUM(Trans) as Trans,
	SUM(Spend) as Spend,
	COUNT(DISTINCT dty.FanID) as Spenders
INTO #BrandVariables
FROM Warehouse.Staging.WRF_654_FinalReferenceTable frt
INNER JOIN #Brands b
	ON frt.PartnerID = b.PartnerID
INNER JOIN #DataTY dty
	ON dty.FanID = frt.FanID
	AND dty.PartnerID = frt.PartnerID
GROUP BY frt.PartnerID,	Gender,	AgeGroup,CAMEO_CODE_Grp,DriveTimeBand
ORDER BY PartnerID, Gender,AgeGroup,CAMEO_CODE_Grp,DriveTimeBand


--SELECT * FROM #BrandVariables
--WHERE PartnerID = 4434
--ORDER BY Gender, AgeGroup,CAMEO_CODE_GRP, DriveTimeBand

/************************************************************
************Creating #Brandprofilingtotal3 table*************
************************************************************/
IF OBJECT_ID('tempdb..#BrandProfilingTotal') IS NOT NULL DROP TABLE #BrandProfilingTotal
SELECT	gd.PartnerID,
	gd.gender,
	gd.CAMEO_CODE_GRP,
	gd.DriveTimeBand,
	gd.AgeGroup,
	gd.CardHolders,
	ISNULL(bv.Trans,0) as PartnerTrans,
	ISNULL(bv.Spend,0) as PartnerSpend,
	ISNULL(bv.Spenders,0) as PartnerSpenders,
	bt.spend as Total_Brand_Spend,
	bt.spenders as Total_Brand_Spenders,
	bt.trans as Total_Brand_Transactions,
	ts.trans as Total_Retail_Trans,
	ts.spend as Total_Retail_Spend,
	ts.spenders as Total_Retail_Spenders
INTO #BrandProfilingTotal
FROM #GeoDemSummary gd
LEFT OUTER JOIN #BrandVariables bv
	ON bv.PartnerID = gd.PartnerID
	AND bv.Gender = gd.Gender
	AND bv.CAMEO_CODE_GRP = gd.CAMEO_CODE_GRP
	AND bv.AgeGroup = gd.AgeGroup
	AND bv.DriveTimeBand = gd.DriveTimeBand
LEFT OUTER JOIN	(
		SELECT	PartnerID,
			SUM(Trans) as Trans,
			SUM(Spend) as Spend,
			SUM(Spenders) as Spenders
		FROM #BrandVariables
		GROUP BY PartnerID
		)bt
	ON gd.PartnerID = bt.PartnerID
CROSS JOIN	(
		SELECT	SUM(Trans) as Trans,
			SUM(Spend) as Spend,
			COUNT(DISTINCT FanID) as Spenders
		FROM #DataTY
		)ts
ORDER BY PartnerID, Gender, CAMEO_CODE_GRP, DriveTimeBand, AgeGroup


--SELECT *
--FROM #BrandProfilingTotal
--WHERE PartnerID = 4434
--ORDER BY PartnerID, Gender, AgeGroup,CAMEO_CODE_GRP, DriveTimeBand

/************************************************************
******Customers with a CINID and Valid CAMEO/Gender/Age******
************************************************************/
IF OBJECT_ID('tempdb..#BrandProfilingTotal_B') IS NOT NULL DROP TABLE #BrandProfilingTotal_B
SELECT	COUNT(DISTINCT da.FanID) as Fixed_Total_Retail_Spenders
INTO #BrandProfilingTotal_B
FROM #FanCINIDs da
INNER JOIN Warehouse.Staging.WRF_654_FinalReferenceTable frt
	ON da.FanID = frt.FanID

--SELECT * FROM #BrandProfilingTotal_B


/***************************************************************************
******Calculating Base and Target AVT,SPS,ATF per Partner, Demographic******
***************************************************************************/
IF OBJECT_ID('tempdb..#BrandProfilingTotal_C') IS NOT NULL DROP TABLE #BrandProfilingTotal_C
SELECT	a.*,
	c.Fixed_Total_Retail_Spenders,
	(((CAST(a.PartnerSpend AS DECIMAL(20,5))/CAST(a.CardHolders AS DECIMAL(20,5))))) as Target_SPC,
	(((CAST(Total_Brand_Spend AS DECIMAL(20,5))/CAST(c.Fixed_Total_Retail_Spenders AS DECIMAL(20,5))))) as Base_SPC,
	(((CAST(a.PartnerSpenders AS DECIMAL(20,5)) / CAST(a.CardHolders AS DECIMAL(20,5))))*100) as Target_Spend_Prop,
	(((CAST(total_brand_spenders AS DECIMAL (20,5)) / CAST (c.fixed_total_retail_spenders AS DECIMAL (20,5))))*100) as Base_Spend_Prop,
	CASE WHEN a.Partnerspend>0 THEN (((CAST(a.Partnerspend AS DECIMAL (20,5)) / CAST (a.Partnerspenders AS DECIMAL (20,5))))) ELSE 0 end as Target_SPS,
	(((CAST(total_brand_spend AS DECIMAL (20,5)) / CAST (total_brand_spenders AS DECIMAL (20,5))))) as Base_SPS,
	CASE WHEN a.Partnerspend>0 THEN (((CAST(a.Partnerspend AS DECIMAL (20,5)) / CAST (a.Partnertrans AS DECIMAL (20,5)))))ELSE 0 end as Target_ATV,
	(((CAST(total_brand_spend AS DECIMAL (20,5)) / CAST (total_brand_transactions AS DECIMAL (20,5))))) as Base_ATV,
	CASE WHEN a.Partnerspend>0 THEN(((CAST(a.Partnertrans AS DECIMAL (20,5)) / CAST (a.Partnerspenders AS DECIMAL (20,5))))) ELSE 0 end as Target_ATF,
	(((CAST(total_brand_transactions AS DECIMAL (20,5)) / CAST (total_brand_spenders AS DECIMAL (20,5))))) as Base_ATF
INTO #BrandProfilingTotal_C 
FROM #BrandProfilingTotal a
CROSS JOIN #BrandProfilingTotal_B c 
ORDER BY PartnerID, Gender, CAMEO_CODE_GRP, DriveTimeBand, AgeGroup



/***************************************************
************Calculating Response Indexes************
***************************************************/
IF OBJECT_ID('tempdb..#BrandProfilingTotal_D') IS NOT NULL DROP TABLE #BrandProfilingTotal_D
select	a.PartnerID,
	1 as Partner_Flag,
	a.Gender,
	a.AgeGroup,
	a.CAMEO_CODE_grp,
	a.DriveTimeBand,
	a.Total_Brand_Spend,
	a.Total_Brand_Spenders,
	a.Total_Brand_Transactions,
	a.Total_Retail_Trans,
	a.Total_Retail_Spend,
	a.Target_SPC,
	a.Base_SPC,
	a.Target_Spend_Prop,
	a.Base_Spend_Prop,
	a.Target_SPS,
	a.Base_SPS,
	a.Target_ATV,
	a.Base_ATV,
	a.Target_ATF,
	a.Base_ATF,
	a.CardHolders as Cardholders_By_Seg,
	a.Fixed_Total_Retail_Spenders,
	(((Target_Spend_Prop/Base_Spend_Prop)*100)) as Response_Index,
	((Target_SPC/Base_SPC)*100) as SPC_Index,
	((Target_SPS/Base_SPS)*100) as SPS_Index,
	((Target_ATV/Base_ATV)*100) as ATV_Index,
	((Target_ATF/Base_ATF)*100) as ATF_Index,
	PartnerTrans,
	PartnerSpend,
	PartnerSpenders
INTO #BrandProfilingTotal_D
FROM #BrandProfilingTotal_C a
INNER JOIN #GeoDemSummary geo 
	ON a.PartnerID = geo.PartnerID 
	AND a.AgeGroup = geo.AgeGroup 
	AND a.CAMEO_CODE_grp = geo.CAMEO_CODE_grp 
	AND a.DriveTimeBand = geo.DriveTimeBand 
	AND a.Gender = geo.Gender
ORDER BY PartnerID, Gender, CAMEO_CODE_GRP, DriveTimeBand, AgeGroup

--SELECT	*
--FROM #BrandProfilingTotal_D
--ORDER BY PartnerID, Gender, CAMEO_CODE_GRP, DriveTimeBand, AgeGroup

/**************************************************************************
*********Setting the Response Index to 100 where people are unknown********
**************************************************************************/
UPDATE	#BrandProfilingTotal_D
SET Response_Index = 100
WHERE	(DriveTimeBand = '99. Unknown' AND PartnerID NOT IN (SELECT PartnerID FROM Staging.GeoDemographicHeatMap_OnlinePartners))
	OR CAMEO_CODE_GRP = '99. Unknown'
	OR Gender = 'U'
	OR AgeGroup = '99. Unknown'



/***************************************************
**************Calculating Response Rank*************
***************************************************/
IF OBJECT_ID('tempdb..#BrandProfilingTotal_E') IS NOT NULL DROP TABLE #BrandProfilingTotal_E
SELECT	a.PartnerID,
	p.BrandID,
	p.PartnerName,
	a.Partner_Flag,
	a.Gender,
	a.AgeGroup,
	a.CAMEO_CODE_GRP,
	a.DriveTimeBand,
	a.Total_Brand_Spend,
	a.Total_Brand_Spenders,
	a.Total_Brand_Transactions,
	a.Target_Spend_Prop,
	a.Base_Spend_Prop,
	a.SPC_Index,
	a.Response_Index,
	a.Fixed_Total_Retail_Spenders,
	a.Cardholders_By_Seg*a.Response_Index as Calculation_RR,
	a.Cardholders_By_Seg*a.spc_Index as Calculation_SPC,
	a.PartnerSpenders * a.sps_index as Calculation_SPS,
	a.PartnerTrans * a.atv_index as Calculation_ATV,
	a.PartnerSpenders * a.atf_index as Calculation_ATF,
	a.Cardholders_By_Seg,
	(1.0*a.PartnerSpenders / a.total_brand_spenders) as Percent_Spenders,
	(1.0*a.cardholders_by_Seg / a.fixed_total_retail_spenders) as Percent_Cardholders,
	a.PartnerSpend,
	a.PartnerSpenders,
	a.PartnerTrans,
	DENSE_RANK() OVER(PARTITION BY a.PartnerID ORDER BY Response_Index DESC) as Response_Rank
INTO #BrandProfilingTotal_E
FROM #BrandProfilingTotal_D a
INNER JOIN Warehouse.Relational.Partner p	
	ON a.PartnerID = p.PartnerID


--SELECT	*
--FROM #BrandProfilingTotal_E
--WHERE PartnerID = 2766
--ORDER BY PartnerID, Gender, AgeGroup, CAMEO_CODE_GRP, DriveTimeBand



IF OBJECT_ID('Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table') IS NOT NULL DROP TABLE Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table
CREATE TABLE Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table
	(
	[LookUpID] INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	[PartnerID] [int] NOT NULL,
	[BrandID] [int] NOT NULL,
	[PartnerName] VARCHAR(200) NOT NULL,
	[Partner_Flag] BIT NOT NULL,
	[Gender] [char](1) NULL,
	[AgeGroup] [varchar](100) NULL,
	[CAMEO_CODE_GRP] [varchar](200) NULL,
	[DriveTimeBand] [varchar](50) NULL,
	[Total_Brand_Spend] [money] NULL,
	[Total_Brand_Spenders] [int] NULL,
	[Total_Brand_Transactions] [int] NULL,
	[Target_Spend_Prop] [decimal](38, 14) NULL,
	[Base_Spend_Prop] [decimal](38, 14) NULL,
	[SPC_Index] [decimal](38, 6) NULL,
	[Response_Index] [decimal](38, 6) NULL,
	[Fixed_Total_Retail_Spenders] [int] NULL,
	[Calculation_RR] [decimal](38, 6) NULL,
	[Calculation_SPC] [decimal](38, 6) NULL,
	[Calculation_SPS] [decimal](38, 6) NULL,
	[Calculation_ATV] [decimal](38, 6) NULL,
	[Calculation_ATF] [decimal](38, 6) NULL,
	[Cardholders_By_Seg] [int] NULL,
	[Percent_Spenders] [numeric](24, 12) NULL,
	[Percent_Cardholders] [numeric](24, 12) NULL,
	[PartnerSpend] [money] NOT NULL,
	[PartnerSpenders] [int] NOT NULL,
	[PartnerTrans] [int] NOT NULL,
	[Response_Rank] [bigint] NULL,
	[Response_Rank2] [bigint] NULL,
	ResponseIndexBand_ID INT NULL,
	[Non_Spenders] [int] NULL,
	[HeatMapID] INT NULL
	)

INSERT INTO Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table 
SELECT	a.*,
	ROW_NUMBER() over(partition by a.PartnerID order by response_index desc) AS Response_Rank2,
	CASE	
		WHEN Response_Index IS NULL OR Response_Index < 20 THEN 1
		WHEN Response_Index BETWEEN 20 AND 40 THEN 2
		WHEN Response_Index BETWEEN 40 AND 50 THEN 3
		WHEN Response_Index BETWEEN 50 AND 60 THEN 4								
		WHEN Response_Index BETWEEN 60 AND 70 THEN 5
		WHEN Response_Index BETWEEN 70 AND 80 THEN 6
		WHEN Response_Index BETWEEN 80 AND 90 THEN 7
		WHEN Response_Index BETWEEN 90 AND 95 THEN 8
		WHEN Response_Index BETWEEN 95 AND 100 THEN 9
		WHEN Response_Index BETWEEN 100 AND 105 THEN 10
		WHEN Response_Index BETWEEN 105 AND 110 THEN 11
		WHEN Response_Index BETWEEN 110 AND 115 THEN 12										
		WHEN Response_Index BETWEEN 115 AND 120 THEN 13						
		WHEN Response_Index BETWEEN 120 AND 130 THEN 14	
		WHEN Response_Index BETWEEN 130 AND 140 THEN 15
		WHEN Response_Index BETWEEN 140 AND 150 THEN 16
		WHEN Response_Index BETWEEN 150 AND 160 THEN 17															
		WHEN Response_Index BETWEEN 160 AND 180 THEN 18
		WHEN Response_Index BETWEEN 180 AND 200 THEN 19
		WHEN Response_Index BETWEEN 200 AND 300 THEN 20
		WHEN Response_Index >300 THEN 21
	END as ResponseIndexBand_ID,	
	Cardholders_By_Seg - PartnerSpenders as Non_Spenders,
	h.HeatMapID											 
FROM #BrandProfilingTotal_E a
LEFT OUTER JOIN Warehouse.Relational.GeoDemographicHeatMap_HeatMapID h
	ON a.Gender = h.Gender
	AND a.AgeGroup = h.AgeGroup
	AND a.CAMEO_CODE_GRP = h.CAMEO_CODE_GRP
	AND a.DriveTimeBand = h.DriveTimeBand



CREATE NONCLUSTERED INDEX IDX_PartnerID ON Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table (PartnerID)
CREATE NONCLUSTERED INDEX IDX_BrandID ON Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table (BrandID)
CREATE NONCLUSTERED INDEX IDX_HeatMapID ON Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table (HeatMapID)

/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_02_Build_RetailerProfiling_LookUpTable' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'GeoDemographicHeatMap_LookUp_Table' 
	AND EndDate IS NULL


/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.GeoDemographicHeatMap_LookUp_Table)
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_02_Build_RetailerProfiling_LookUpTable' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'GeoDemographicHeatMap_LookUp_Table' 
	AND TableRowCount IS NULL


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
INSERT INTO staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

END