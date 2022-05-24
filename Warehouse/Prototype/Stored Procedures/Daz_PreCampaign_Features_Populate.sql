-- =============================================
-- Author:		Shaun H.
-- Create date: 25th June 2019
-- Description:	Derive pre-campaign features for Exposed and Control group.
-- =============================================
CREATE PROCEDURE [Prototype].[Daz_PreCampaign_Features_Populate]
  @CampaignID INT,
  @Sector VARCHAR(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- Test rig
	--DECLARE @CampaignID INT = 1
	--DECLARE @Sector VARCHAR(200) = '292' --'5,21,92,254,292,379,425,485'

	DECLARE @time DATETIME
	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - Start', @time OUTPUT

	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer	
	SELECT 
		IronOfferID,
		IronOfferName,
		StartDate,
		EndDate,
		PartnerID,
		BelowThresholdRate,
		MinimumBasketSize,
		AboveThresholdRate
	INTO #IronOffer
	FROM Warehouse.Prototype.Daz_Campaign_List
	WHERE CampaignID = @CampaignID

	CREATE CLUSTERED INDEX cix_IronOfferID ON #IronOffer (IronOfferID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID__StartDate_PartnerID ON #IronOffer (IronOfferID) INCLUDE (StartDate,PartnerID)

	------------------------------------------------------------------
	-- Find Exposed

	IF OBJECT_ID('tempdb..#IronOfferMembers') IS NOT NULL DROP TABLE #IronOfferMembers
	SELECT
		iom.IronOfferID,
		iom.CompositeID,
		CAST(iom.StartDate AS DATE) AS StartDate,
		CAST(iom.EndDate AS DATE) AS EndDate
	INTO #IronOfferMembers
	FROM SLC_Report..IronOfferMember iom
	JOIN #IronOffer io
		ON iom.IronOfferID = io.IronOfferID
		AND iom.StartDate = io.StartDate

	CREATE CLUSTERED INDEX cix_CompositeID ON #IronOfferMembers (CompositeID)

	IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
	SELECT
		iom.IronOfferID,
		c.FanID,
		iom.StartDate,
		iom.EndDate
	INTO #Exposed
	FROM #IronOfferMembers iom
	JOIN Warehouse.Relational.Customer c
		ON iom.CompositeID = c.CompositeID

	CREATE CLUSTERED INDEX cix_FanID ON #Exposed (FanID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID ON #Exposed (IronOfferID) INCLUDE (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Exposed', @time OUTPUT

	------------------------------------------------------------------
	-- Find Control

	IF OBJECT_ID('tempdb..#Control') IS NOT NULL DROP TABLE #Control
	SELECT
	  ip.IronOfferID,
	  ip.FanID,
	  CAST(ip.StartDate AS DATE) AS StartDate,
	  CAST(ip.EndDate AS DATE) AS EndDate
	INTO #Control
	FROM [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ip
	JOIN #IronOffer io
	  ON ip.StartDate = io.StartDate
	 AND ip.IronOfferID = io.IronOfferID
	 AND ip.PartnerID = io.PartnerID
	WHERE
	  ip.ExcludeFromAnalysis = 0

	CREATE CLUSTERED INDEX cix_FanID ON #Control (FanID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID ON #Control (IronOfferID) INCLUDE (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Control', @time OUTPUT

	------------------------------------------------------------------
	-- Combine

	IF OBJECT_ID('tempdb..#Profiling') IS NOT NULL DROP TABLE #Profiling
	SELECT
	  IronOfferID,
	  FanID,
	  StartDate,
	  EndDate,
	  GroupName
	INTO #Profiling
	FROM
	 (SELECT
	   *,
	   'E' AS GroupName
	  FROM #Exposed
	  UNION
	  SELECT
	   *,
	   'C' AS GroupName
	  FROM #Control
	 ) a

	CREATE CLUSTERED INDEX cix_FanID ON #Profiling (FanID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID ON #Profiling (IronOfferID) INCLUDE (FanID)
	CREATE NONCLUSTERED INDEX nix_GroupName ON #Profiling (GroupName) INCLUDE (FanID)

	IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID
	SELECT
	  p.*,
	  cin.CINID,
	  o.BelowThresholdRate,
	  o.MinimumBasketSize,
	  o.AboveThresholdRate
	INTO #CINID
	FROM #Profiling p
	JOIN Warehouse.Relational.Customer c
	  ON p.FanID = c.FanID
	LEFT JOIN Warehouse.Relational.CINList cin
	  ON c.SourceUID = cin.CIN
	JOIN #IronOffer o
	  ON p.IronOfferID = o.IronOfferID

	CREATE CLUSTERED INDEX cix_CINID ON #CINID (CINID)
	CREATE NONCLUSTERED INDEX nix_IronOfferID ON #CINID (IronOfferID) INCLUDE (CINID)
	CREATE NONCLUSTERED INDEX nix_GroupName ON #CINID (GroupName) INCLUDE (CINID)

	-- Assign needed parameters
	DECLARE @PartnerID INT,
			@StartDate DATE,
			@EndDate DATE,
			@BrandID INT
	
	SELECT
	  @PartnerID = MIN(PartnerID),
	  @StartDate = MIN(StartDate),
	  @EndDate = MIN(EndDate)
	FROM #IronOffer

	SELECT
	  @BrandID = BrandID
	FROM Warehouse.Relational.Partner
	WHERE PartnerID = @PartnerID

	-- Derive the date parameters
	DECLARE @PrePeriodStartDate DATE = DATEADD(DAY,-364,@StartDate)
	DECLARE @PrePeriodEndDate DATE = DATEADD(DAY,-1,@StartDate)
	-- 364 Days of Pre Period

	-- Generate a date table
	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	SELECT	Cycles,
			StartDate,
			EndDate
	INTO	#Dates
	FROM  (
			SELECT	1 AS Cycles,
					DATEADD(DAY,-27,@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	2 AS Cycles,
					DATEADD(DAY,-(27+28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	3 AS Cycles,
					DATEADD(DAY,-(27+2*28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	4 AS Cycles,
					DATEADD(DAY,-(27+3*28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	5 AS Cycles,
					DATEADD(DAY,-(27+4*28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	6 AS Cycles,
					DATEADD(DAY,-(27+5*28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
			UNION
			SELECT	13 AS Cycles,
					DATEADD(DAY,-(27+12*28),@PrePeriodEndDate) AS StartDate,
					@PrePeriodEndDate AS EndDate
		  ) a

	CREATE CLUSTERED INDEX cix_DateRow ON #Dates (Cycles)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #Dates (StartDate)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #Dates (EndDate)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Dates', @time OUTPUT

	------------------------------------------------------------------------------------
	/* START: Personal Features */
	------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#PostalSector') IS NOT NULL DROP TABLE #PostalSector
	SELECT	DISTINCT PostalSector
	INTO	#PostalSector
	FROM	Warehouse.Relational.Customer c WITH (NOLOCK)

	CREATE CLUSTERED INDEX cix_PostalSector ON #PostalSector (PostalSector)

	IF OBJECT_ID('tempdb..#StorePostCodes') IS NOT NULL DROP TABLE #StorePostCodes
	SELECT	o.*
	INTO	#StorePostcodes
	FROM	(	
				SELECT	PartnerID,
						PostalSector
				FROM	Warehouse.Relational.Outlet
				UNION 
				SELECT	PartnerID,
						PostalSector
				FROM	NFI.Relational.Outlet
			) o
	JOIN	Warehouse.Relational.Partner p
		ON	o.PartnerID = p.PartnerID
		AND	p.PartnerID = @PartnerID
	WHERE	o.PostalSector IS NOT NULL
		AND o.PostalSector <> ''

	CREATE CLUSTERED INDEX ix_PostalSector ON #StorePostcodes (PostalSector)

	IF OBJECT_ID('tempdb..#Proximity') IS NOT NULL DROP TABLE #Proximity
	SELECT	CustomerPostalSector AS PostalSector,
			MIN(DriveTimeMins) AS MinDriveTime,
			MIN(DriveDistMiles) AS MinDriveDist
	INTO	#Proximity
	FROM  (
			SELECT	a.PostalSector AS CustomerPostalSector,
					b.PostalSector AS StorePostalSector,
					dtm.DriveTimeMins,
					dtm.DriveDistMiles
			FROM	#PostalSector a
			LEFT JOIN Warehouse.Relational.DriveTimeMatrix dtm
				ON	a.PostalSector = dtm.FromSector
			LEFT JOIN #StorePostCodes b
				ON	dtm.ToSector = b.PostalSector
		  ) dt
	GROUP BY CustomerPostalSector

	CREATE CLUSTERED INDEX cix_PostalSector ON #Proximity (PostalSector)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Proximity', @time OUTPUT

	IF OBJECT_ID('tempdb..#PersonalFeatures') IS NOT NULL DROP TABLE #PersonalFeatures
	SELECT	d.FanID,
			d.Gender,
			d.AgeCurrent,
			d.HeatmapCameoGroup,
			COALESCE(hm.HeatmapIndex,100) AS HeatmapScore,
			COALESCE(p.MinDriveTime,60) AS MinDriveTime,
			COALESCE(p.MinDriveDist,60) AS MinDriveDist,
			CASE WHEN pm.PaymentMethodsAvailableID IN (0,2) THEN 1 ELSE 0 END AS HasDD,
			CASE WHEN pm.PaymentMethodsAvailableID IN (1,2) THEN 1 ELSE 0 END AS HasCC
	INTO	#PersonalFeatures
	FROM  (
			SELECT	c.FanID,
					c.Gender,
					c.PostalSector,
					c.AgeCurrent,
					CASE	
						WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
						WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
						WHEN c.AgeCurrent BETWEEN 25 AND 34 THEN '02. 25 to 34'
						WHEN c.AgeCurrent BETWEEN 35 AND 44 THEN '03. 35 to 44'
						WHEN c.AgeCurrent BETWEEN 45 AND 54 THEN '04. 45 to 54'
						WHEN c.AgeCurrent BETWEEN 55 AND 64 THEN '05. 55 to 64'
						WHEN c.AgeCurrent >= 65 THEN '06. 65+' 
					END AS HeatmapAgeGroup,
					ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			FROM	Warehouse.Relational.Customer c WITH (NOLOCK)
			JOIN	#CINID f
				ON	c.FanID = f.FanID
			LEFT JOIN	Warehouse.Relational.CAMEO cam WITH (NOLOCK)
				ON	cam.postcode = c.postcode
			LEFT JOIN	Warehouse.Relational.Cameo_Code_Group camg WITH (NOLOCK)
				ON	camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP
		  ) d
	LEFT JOIN	Warehouse.Relational.HeatmapCombinations com
		ON	d.Gender = com.Gender 
		AND	d.HeatmapCameoGroup = com.HeatmapCameoGroup
		AND d.HeatmapAgeGroup = com.HeatmapAgeGroup
	LEFT JOIN	Warehouse.Relational.HeatmapScore_POS hm
		ON	com.ComboID = hm.ComboID
		AND	hm.BrandID = @BrandID
	LEFT JOIN	#Proximity p
		ON	d.PostalSector = p.PostalSector
	LEFT JOIN	
		(	SELECT	pm.FanID,
					pm.PaymentMethodsAvailableID
			FROM	Warehouse.Relational.CustomerPaymentMethodsAvailable pm
			JOIN	#CINID f
				ON	pm.FanID = f.FanID
			WHERE	pm.StartDate <= @PrePeriodEndDate
				AND	(@PrePeriodEndDate < pm.EndDate OR pm.EndDate IS NULL) 
		) pm
		ON	d.FanID = pm.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #PersonalFeatures (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #PersonalFeatures', @time OUTPUT

	/* END: Personal Features */

	------------------------------------------------------------------------------------
	/* START: Transactional Features */
	------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	BrandID,
			ConsumerCombinationID,
			CASE WHEN BrandID = @BrandID THEN 1 ELSE 0 END AS MainBrand
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @Sector + ',') > 0
		OR	BrandID = @BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ConsumerCombinationID ON #CC (ConsumerCombinationID) INCLUDE (MainBrand)
	
	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #CC', @time OUTPUT

	DECLARE @MinTranDate DATE,
			@MaxTranDate DATE

	SELECT	@MinTranDate = MIN(StartDate),
			@MaxTranDate = MAX(EndDate)
	FROM	#Dates

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	ct.CINID
			,ct.Amount
			,ct.IsOnline
			,ct.TranDate
			,cc.MainBrand
			,ct.PaymentTypeID
	INTO	#Trans
	FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN	#CC cc
		ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
	JOIN	#CINID mrb
		ON	mrb.CINID = ct.CINID
	WHERE  ct.TranDate BETWEEN @MinTranDate and @MaxTranDate
		AND 0 < ct.Amount

	CREATE CLUSTERED INDEX cix_TranDate ON #Trans (TranDate)
	CREATE NONCLUSTERED INDEX nix_TranDate_CINID ON #Trans (TranDate) INCLUDE (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Trans', @time OUTPUT

	IF OBJECT_ID('tempdb..#PrePivotTransactions') IS NOT NULL DROP TABLE #PrePivotTransactions
	SELECT	CINID,
			Cycles,
			Sales,
			Frequency,
			DATEDIFF(DAY,Recency,EndDate) AS Recency,
			MainBrand_Sales,
			MainBrand_Frequency,
			DATEDIFF(DAY,MainBrand_Recency,EndDate) AS MainBrand_Recency,
			Online_Sales,
			Online_Frequency,
			DATEDIFF(DAY,Online_Recency,EndDate) AS Online_Recency,
			CreditCard_Sales,
			CreditCard_Frequency,
			DATEDIFF(DAY,CreditCard_Recency,EndDate) AS CreditCard_Recency
	INTO	#PrePivotTransactions
	FROM  (
			SELECT	t.CINID,
					d.Cycles,
					d.StartDate,
					d.EndDate,
					SUM(t.Amount) AS Sales,
					COUNT(t.Amount) AS Frequency,
					MAX(t.TranDate) AS Recency,
					SUM(CASE WHEN t.MainBrand=1 THEN t.Amount ELSE 0 END) AS MainBrand_Sales,
					COUNT(CASE WHEN t.MainBrand=1 THEN t.Amount ELSE 0 END) AS MainBrand_Frequency,
					MAX(CASE WHEN t.MainBrand=1 THEN t.TranDate END) AS MainBrand_Recency,
					SUM(CASE WHEN t.IsOnline=1 THEN t.Amount ELSE 0 END) AS Online_Sales,
					COUNT(CASE WHEN t.IsOnline=1 THEN t.Amount ELSE 0 END) AS Online_Frequency,
					MAX(CASE WHEN t.IsOnline=1 THEN t.TranDate END) AS Online_Recency,
					SUM(CASE WHEN t.PaymentTypeID=2 THEN t.Amount ELSE 0 END) AS CreditCard_Sales,
					COUNT(CASE WHEN t.PaymentTypeID=2 THEN t.Amount ELSE 0 END) AS CreditCard_Frequency,
					MAX(CASE WHEN t.PaymentTypeID=2 THEN t.TranDate END) AS CreditCard_Recency
			FROM	#Trans t WITH (NOLOCK)
			JOIN	#Dates d
				ON	d.StartDate <= t.TranDate AND t.TranDate <= d.EndDate
			GROUP BY t.CINID,
					 d.Cycles,
					 d.StartDate,
					 d.EndDate
			) a

	CREATE CLUSTERED INDEX cix_CINID ON #PrePivotTransactions (CINID)
	CREATE NONCLUSTERED INDEX nix_CINID_Cycles ON #PrePivotTransactions (CINID) INCLUDE (Cycles)
	
	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #PrePivotTransactions', @time OUTPUT

	IF OBJECT_ID('tempdb..#Pivoted') IS NOT NULL DROP TABLE #Pivoted
	CREATE TABLE #Pivoted
		(
			CINID	INT	,
			Sales_1	MONEY	,
			Frequency_1	INT	,
			Recency_1	INT	,
			MainBrand_Sales_1	MONEY	,
			MainBrand_Frequency_1	INT	,
			MainBrand_Recency_1	INT	,
			Online_Sales_1	MONEY	,
			Online_Frequency_1	INT	,
			Online_Recency_1	INT	,
			CreditCard_Sales_1	MONEY	,
			CreditCard_Frequency_1	INT	,
			CreditCard_Recency_1	INT	,
			Sales_2	MONEY	,
			Frequency_2	INT	,
			Recency_2	INT	,
			MainBrand_Sales_2	MONEY	,
			MainBrand_Frequency_2	INT	,
			MainBrand_Recency_2	INT	,
			Online_Sales_2	MONEY	,
			Online_Frequency_2	INT	,
			Online_Recency_2	INT	,
			CreditCard_Sales_2	MONEY	,
			CreditCard_Frequency_2	INT	,
			CreditCard_Recency_2	INT	,
			Sales_3	MONEY	,
			Frequency_3	INT	,
			Recency_3	INT	,
			MainBrand_Sales_3	MONEY	,
			MainBrand_Frequency_3	INT	,
			MainBrand_Recency_3	INT	,
			Online_Sales_3	MONEY	,
			Online_Frequency_3	INT	,
			Online_Recency_3	INT	,
			CreditCard_Sales_3	MONEY	,
			CreditCard_Frequency_3	INT	,
			CreditCard_Recency_3	INT	,
			Sales_4	MONEY	,
			Frequency_4	INT	,
			Recency_4	INT	,
			MainBrand_Sales_4	MONEY	,
			MainBrand_Frequency_4	INT	,
			MainBrand_Recency_4	INT	,
			Online_Sales_4	MONEY	,
			Online_Frequency_4	INT	,
			Online_Recency_4	INT	,
			CreditCard_Sales_4	MONEY	,
			CreditCard_Frequency_4	INT	,
			CreditCard_Recency_4	INT	,
			Sales_5	MONEY	,
			Frequency_5	INT	,
			Recency_5	INT	,
			MainBrand_Sales_5	MONEY	,
			MainBrand_Frequency_5	INT	,
			MainBrand_Recency_5	INT	,
			Online_Sales_5	MONEY	,
			Online_Frequency_5	INT	,
			Online_Recency_5	INT	,
			CreditCard_Sales_5	MONEY	,
			CreditCard_Frequency_5	INT	,
			CreditCard_Recency_5	INT	,
			Sales_6	MONEY	,
			Frequency_6	INT	,
			Recency_6	INT	,
			MainBrand_Sales_6	MONEY	,
			MainBrand_Frequency_6	INT	,
			MainBrand_Recency_6	INT	,
			Online_Sales_6	MONEY	,
			Online_Frequency_6	INT	,
			Online_Recency_6	INT	,
			CreditCard_Sales_6	MONEY	,
			CreditCard_Frequency_6	INT	,
			CreditCard_Recency_6	INT	,
			Sales_13	MONEY	,
			Frequency_13	INT	,
			Recency_13	INT	,
			MainBrand_Sales_13	MONEY	,
			MainBrand_Frequency_13	INT	,
			MainBrand_Recency_13	INT	,
			Online_Sales_13	MONEY	,
			Online_Frequency_13	INT	,
			Online_Recency_13	INT	,
			CreditCard_Sales_13	MONEY	,
			CreditCard_Frequency_13	INT	,
			CreditCard_Recency_13	INT	
		)


	INSERT INTO #Pivoted
		SELECT	CINID,
				Sales,
				Frequency,
				Recency,
				MainBrand_Sales,
				MainBrand_Frequency,
				MainBrand_Recency,
				Online_Sales,
				Online_Frequency,
				Online_Recency,
				CreditCard_Sales,
				CreditCard_Frequency,
				CreditCard_Recency,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		FROM	#PrePivotTransactions
		WHERE	Cycles = 1

	CREATE CLUSTERED INDEX cix_CINID ON #Pivoted (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Pivoted', @time OUTPUT

	UPDATE o
	SET		-- 2 Month
			Sales_2 = ppt2.Sales,
			Frequency_2 =  ppt2.Frequency,
			Recency_2 =  ppt2.Recency,
			MainBrand_Sales_2 = ppt2.MainBrand_Sales,
			MainBrand_Frequency_2 =  ppt2.MainBrand_Frequency,
			MainBrand_Recency_2 = ppt2.MainBrand_Recency,
			Online_Sales_2 = ppt2.Online_Sales,
			Online_Frequency_2 = ppt2.Online_Frequency,
			Online_Recency_2 = ppt2.Online_Recency,
			CreditCard_Sales_2 = ppt2.CreditCard_Sales,
			CreditCard_Frequency_2 = ppt2.CreditCard_Frequency,
			CreditCard_Recency_2 = ppt2.CreditCard_Recency,
			-- 3 Month
			Sales_3 = ppt3.Sales,
			Frequency_3 =  ppt3.Frequency,
			Recency_3 =  ppt3.Recency,
			MainBrand_Sales_3 = ppt3.MainBrand_Sales,
			MainBrand_Frequency_3 =  ppt3.MainBrand_Frequency,
			MainBrand_Recency_3 = ppt3.MainBrand_Recency,
			Online_Sales_3 = ppt3.Online_Sales,
			Online_Frequency_3 = ppt3.Online_Frequency,
			Online_Recency_3 = ppt3.Online_Recency,
			CreditCard_Sales_3 = ppt3.CreditCard_Sales,
			CreditCard_Frequency_3 = ppt3.CreditCard_Frequency,
			CreditCard_Recency_3 = ppt3.CreditCard_Recency,
			-- 4 Month
			Sales_4 = ppt4.Sales,
			Frequency_4 =  ppt4.Frequency,
			Recency_4 =  ppt4.Recency,
			MainBrand_Sales_4 = ppt4.MainBrand_Sales,
			MainBrand_Frequency_4 =  ppt4.MainBrand_Frequency,
			MainBrand_Recency_4 = ppt4.MainBrand_Recency,
			Online_Sales_4 = ppt4.Online_Sales,
			Online_Frequency_4 = ppt4.Online_Frequency,
			Online_Recency_4 = ppt4.Online_Recency,
			CreditCard_Sales_4 = ppt4.CreditCard_Sales,
			CreditCard_Frequency_4 = ppt4.CreditCard_Frequency,
			CreditCard_Recency_4 = ppt4.CreditCard_Recency,
			-- 5 Month
			Sales_5 = ppt5.Sales,
			Frequency_5 =  ppt5.Frequency,
			Recency_5 =  ppt5.Recency,
			MainBrand_Sales_5 = ppt5.MainBrand_Sales,
			MainBrand_Frequency_5 =  ppt5.MainBrand_Frequency,
			MainBrand_Recency_5 = ppt5.MainBrand_Recency,
			Online_Sales_5 = ppt5.Online_Sales,
			Online_Frequency_5 = ppt5.Online_Frequency,
			Online_Recency_5 = ppt5.Online_Recency,
			CreditCard_Sales_5 = ppt5.CreditCard_Sales,
			CreditCard_Frequency_5 = ppt5.CreditCard_Frequency,
			CreditCard_Recency_5 = ppt5.CreditCard_Recency,
			-- 6 Month
			Sales_6 = ppt6.Sales,
			Frequency_6 =  ppt6.Frequency,
			Recency_6 =  ppt6.Recency,
			MainBrand_Sales_6 = ppt6.MainBrand_Sales,
			MainBrand_Frequency_6 =  ppt6.MainBrand_Frequency,
			MainBrand_Recency_6 = ppt6.MainBrand_Recency,
			Online_Sales_6 = ppt6.Online_Sales,
			Online_Frequency_6 = ppt6.Online_Frequency,
			Online_Recency_6 = ppt6.Online_Recency,
			CreditCard_Sales_6 = ppt6.CreditCard_Sales,
			CreditCard_Frequency_6 = ppt6.CreditCard_Frequency,
			CreditCard_Recency_6 = ppt6.CreditCard_Recency,
			-- 13 Month
			Sales_13 = ppt13.Sales,
			Frequency_13 =  ppt13.Frequency,
			Recency_13 =  ppt13.Recency,
			MainBrand_Sales_13 = ppt13.MainBrand_Sales,
			MainBrand_Frequency_13 =  ppt13.MainBrand_Frequency,
			MainBrand_Recency_13 = ppt13.MainBrand_Recency,
			Online_Sales_13 = ppt13.Online_Sales,
			Online_Frequency_13 = ppt13.Online_Frequency,
			Online_Recency_13 = ppt13.Online_Recency,
			CreditCard_Sales_13 = ppt13.CreditCard_Sales,
			CreditCard_Frequency_13 = ppt13.CreditCard_Frequency,
			CreditCard_Recency_13 = ppt13.CreditCard_Recency
	FROM	#Pivoted o
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 2 ) ppt2
		ON	o.CINID = ppt2.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 3 ) ppt3
		ON	o.CINID = ppt3.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 4 ) ppt4
		ON	o.CINID = ppt4.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 5 ) ppt5
		ON	o.CINID = ppt5.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 6 ) ppt6
		ON	o.CINID = ppt6.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 13 ) ppt13
		ON	o.CINID = ppt13.CINID

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - Updated #Pivoted', @time OUTPUT

	IF OBJECT_ID('tempdb..#TransactionalFeatures') IS NOT NULL DROP TABLE #TransactionalFeatures
	SELECT	a.FanID
			,a.CINID
			,Sales_1
			,Frequency_1
			,Recency_1
			,MainBrand_Sales_1
			,MainBrand_Frequency_1
			,MainBrand_Recency_1
			,Online_Sales_1
			,Online_Frequency_1
			,Online_Recency_1
			,CreditCard_Sales_1
			,CreditCard_Frequency_1
			,CreditCard_Recency_1
			,Sales_2
			,Frequency_2
			,Recency_2
			,MainBrand_Sales_2
			,MainBrand_Frequency_2
			,MainBrand_Recency_2
			,Online_Sales_2
			,Online_Frequency_2
			,Online_Recency_2
			,CreditCard_Sales_2
			,CreditCard_Frequency_2
			,CreditCard_Recency_2
			,Sales_3
			,Frequency_3
			,Recency_3
			,MainBrand_Sales_3
			,MainBrand_Frequency_3
			,MainBrand_Recency_3
			,Online_Sales_3
			,Online_Frequency_3
			,Online_Recency_3
			,CreditCard_Sales_3
			,CreditCard_Frequency_3
			,CreditCard_Recency_3
			,Sales_4
			,Frequency_4
			,Recency_4
			,MainBrand_Sales_4
			,MainBrand_Frequency_4
			,MainBrand_Recency_4
			,Online_Sales_4
			,Online_Frequency_4
			,Online_Recency_4
			,CreditCard_Sales_4
			,CreditCard_Frequency_4
			,CreditCard_Recency_4
			,Sales_5
			,Frequency_5
			,Recency_5
			,MainBrand_Sales_5
			,MainBrand_Frequency_5
			,MainBrand_Recency_5
			,Online_Sales_5
			,Online_Frequency_5
			,Online_Recency_5
			,CreditCard_Sales_5
			,CreditCard_Frequency_5
			,CreditCard_Recency_5
			,Sales_6
			,Frequency_6
			,Recency_6
			,MainBrand_Sales_6
			,MainBrand_Frequency_6
			,MainBrand_Recency_6
			,Online_Sales_6
			,Online_Frequency_6
			,Online_Recency_6
			,CreditCard_Sales_6
			,CreditCard_Frequency_6
			,CreditCard_Recency_6
			,Sales_13
			,Frequency_13
			,Recency_13
			,MainBrand_Sales_13
			,MainBrand_Frequency_13
			,MainBrand_Recency_13
			,Online_Sales_13
			,Online_Frequency_13
			,Online_Recency_13
			,CreditCard_Sales_13
			,CreditCard_Frequency_13
			,CreditCard_Recency_13
	INTO	#TransactionalFeatures
	FROM	#CINID a
	LEFT JOIN	#Pivoted b
		ON	a.CINID = b.CINID

	CREATE CLUSTERED INDEX cix_FanID ON #TransactionalFeatures (FanID)
	
	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - Updated #TransactionalFeatures', @time OUTPUT

	/* END: Transactional Features */

	------------------------------------------------------------------------------------
	/* START: Engagement Features */
	------------------------------------------------------------------------------------

	-- DECLARE @CampaignStartDate DATE = '2018-07-05'

	-- MarketableByEmail
	IF OBJECT_ID('tempdb..#Marketable') IS NOT NULL DROP TABLE #Marketable
	SELECT	f.FanID,
			m.MarketableByEmail
	INTO	#Marketable
	FROM	#CINID f
	JOIN	Warehouse.Relational.Customer_MarketableByEmailStatus m
		ON	f.FanID = m.FanID
	WHERE	m.StartDate < @StartDate
		AND	(m.EndDate IS NULL OR @StartDate <= m.EndDate )

	CREATE CLUSTERED INDEX cix_FanID ON #Marketable (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #Marketable', @time OUTPUT

	-- EmailOpens

	IF OBJECT_ID('tempdb..#EmailOpenEvents') IS NOT NULL DROP TABLE #EmailOpenEvents
	SELECT	f.FanID,
			COUNT(CASE WHEN d.Cycles = 1 THEN EventID ELSE NULL END) AS EmailOpenEvents_1Cycle,
			COUNT(CASE WHEN d.Cycles = 2 THEN EventID ELSE NULL END) AS EmailOpenEvents_2Cycle,
			COUNT(CASE WHEN d.Cycles = 3 THEN EventID ELSE NULL END) AS EmailOpenEvents_3Cycle,
			COUNT(CASE WHEN d.Cycles = 6 THEN EventID ELSE NULL END) AS EmailOpenEvents_6Cycle
	INTO	#EmailOpenEvents
	FROM	#CINID f
	JOIN	Warehouse.Relational.EmailEvent ee
		ON	f.FanID = ee.FanID
	JOIN  (	
			SELECT	DISTINCT CampaignKey
			FROM	Warehouse.Relational.EmailCampaign
			WHERE	CampaignName LIKE '%NEWSLETTER%'
				AND CampaignName NOT LIKE '%COPY%' 
				AND CampaignName NOT LIKE '%TEST%'
			) cls -- List of Newsletter emails
		ON	ee.CampaignKey = cls.CampaignKey
	JOIN	#Dates d
		ON	d.StartDate <= ee.EventDate AND ee.EventDate <= d.EndDate
	WHERE	d.Cycles IN (1,2,3,6)
		AND	ee.EmailEventCodeID IN (605,1301)
	GROUP BY f.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #EmailOpenEvents (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #EmailOpenEvents', @time OUTPUT

	-- WebLogins

	IF OBJECT_ID('tempdb..#WebLogins') IS NOT NULL DROP TABLE #WebLogins
	SELECT	f.FanID,
			COUNT(CASE WHEN d.Cycles = 1 THEN TrackDate ELSE NULL END) AS WebLogins_1Cycle,
			COUNT(CASE WHEN d.Cycles = 2 THEN TrackDate ELSE NULL END) AS WebLogins_2Cycle,
			COUNT(CASE WHEN d.Cycles = 3 THEN TrackDate ELSE NULL END) AS WebLogins_3Cycle,
			COUNT(CASE WHEN d.Cycles = 6 THEN TrackDate ELSE NULL END) AS WebLogins_6Cycle
	INTO	#WebLogins
	FROM	#CINID f
	JOIN	Warehouse.Relational.WebLogins wl
		ON	f.FanID = wl.FanID
	JOIN	#Dates d
		ON	d.StartDate <= wl.TrackDate AND wl.TrackDate < DATEADD(DAY,1,d.EndDate)
	WHERE	d.Cycles IN (1,6)
	GROUP BY f.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #WebLogins (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - #WebLogins', @time OUTPUT

	/* END: Engagement Features */

	ALTER INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_PreCampaign_Features DISABLE

	INSERT INTO Warehouse.Prototype.Daz_PreCampaign_Features
		SELECT
		   a.CINID
		  ,a.IronOfferID
		  ,a.FanID
		  ,a.GroupName
		  ,a.StartDate
		  ,a.EndDate
		  ,p.Gender
		  ,p.AgeCurrent
		  ,p.HeatmapCameoGroup
		  ,p.HeatmapScore
		  ,p.MinDriveTime
		  ,p.MinDriveDist
		  ,p.HasDD
		  ,p.HasCC
		  ,COALESCE(t.Sales_1,0) AS Sales_1
		  ,COALESCE(t.Frequency_1,0) AS Frequency_1
		  ,COALESCE(t.Recency_1,28) AS Recency_1
		  ,COALESCE(t.MainBrand_Sales_1,0) AS MainBrand_Sales_1
		  ,COALESCE(t.MainBrand_Frequency_1,0) AS MainBrand_Frequency_1
		  ,COALESCE(t.MainBrand_Recency_1,28) AS MainBrand_Recency_1
		  ,COALESCE(t.Online_Sales_1,0) AS Online_Sales_1
		  ,COALESCE(t.Online_Frequency_1,0) AS Online_Frequency_1
		  ,COALESCE(t.Online_Recency_1,28) AS Online_Recency_1
		  ,COALESCE(t.CreditCard_Sales_1,0) AS CreditCard_Sales_1
		  ,COALESCE(t.CreditCard_Frequency_1,0) AS CreditCard_Frequency_1
		  ,COALESCE(t.CreditCard_Recency_1,28) AS CreditCard_Recency_1
		  ,COALESCE(t.Sales_2,0) AS Sales_2
		  ,COALESCE(t.Frequency_2,0) AS Frequency_2
		  ,COALESCE(t.Recency_2,56) AS Recency_2
		  ,COALESCE(t.MainBrand_Sales_2,0) AS MainBrand_Sales_2
		  ,COALESCE(t.MainBrand_Frequency_2,0) AS MainBrand_Frequency_2
		  ,COALESCE(t.MainBrand_Recency_2,56) AS MainBrand_Recency_2
		  ,COALESCE(t.Online_Sales_2,0) AS Online_Sales_2
		  ,COALESCE(t.Online_Frequency_2,0) AS Online_Frequency_2
		  ,COALESCE(t.Online_Recency_2,56) AS Online_Recency_2
		  ,COALESCE(t.CreditCard_Sales_2,0) AS CreditCard_Sales_2
		  ,COALESCE(t.CreditCard_Frequency_2,0) AS CreditCard_Frequency_2
		  ,COALESCE(t.CreditCard_Recency_2,56) AS CreditCard_Recency_2
		  ,COALESCE(t.Sales_3,0) AS Sales_3
		  ,COALESCE(t.Frequency_3,0) AS Frequency_3
		  ,COALESCE(t.Recency_3,84) AS Recency_3
		  ,COALESCE(t.MainBrand_Sales_3,0) AS MainBrand_Sales_3
		  ,COALESCE(t.MainBrand_Frequency_3,0) AS MainBrand_Frequency_3
		  ,COALESCE(t.MainBrand_Recency_3,84) AS MainBrand_Recency_3
		  ,COALESCE(t.Online_Sales_3,0) AS Online_Sales_3
		  ,COALESCE(t.Online_Frequency_3,0) AS Online_Frequency_3
		  ,COALESCE(t.Online_Recency_3,84) AS Online_Recency_3
		  ,COALESCE(t.CreditCard_Sales_3,0) AS CreditCard_Sales_3
		  ,COALESCE(t.CreditCard_Frequency_3,0) AS CreditCard_Frequency_3
		  ,COALESCE(t.CreditCard_Recency_3,84) AS CreditCard_Recency_3
		  ,COALESCE(t.Sales_4,0) AS Sales_4
		  ,COALESCE(t.Frequency_4,0) AS Frequency_4
		  ,COALESCE(t.Recency_4,112) AS Recency_4
		  ,COALESCE(t.MainBrand_Sales_4,0) AS MainBrand_Sales_4
		  ,COALESCE(t.MainBrand_Frequency_4,0) AS MainBrand_Frequency_4
		  ,COALESCE(t.MainBrand_Recency_4,112) AS MainBrand_Recency_4
		  ,COALESCE(t.Online_Sales_4,0) AS Online_Sales_4
		  ,COALESCE(t.Online_Frequency_4,0) AS Online_Frequency_4
		  ,COALESCE(t.Online_Recency_4,112) AS Online_Recency_4
		  ,COALESCE(t.CreditCard_Sales_4,0) AS CreditCard_Sales_4
		  ,COALESCE(t.CreditCard_Frequency_4,0) AS CreditCard_Frequency_4
		  ,COALESCE(t.CreditCard_Recency_4,112) AS CreditCard_Recency_4
		  ,COALESCE(t.Sales_5,0) AS Sales_5
		  ,COALESCE(t.Frequency_5,0) AS Frequency_5
		  ,COALESCE(t.Recency_5,140) AS Recency_5
		  ,COALESCE(t.MainBrand_Sales_5,0) AS MainBrand_Sales_5
		  ,COALESCE(t.MainBrand_Frequency_5,0) AS MainBrand_Frequency_5
		  ,COALESCE(t.MainBrand_Recency_5,140) AS MainBrand_Recency_5
		  ,COALESCE(t.Online_Sales_5,0) AS Online_Sales_5
		  ,COALESCE(t.Online_Frequency_5,0) AS Online_Frequency_5
		  ,COALESCE(t.Online_Recency_5,140) AS Online_Recency_5
		  ,COALESCE(t.CreditCard_Sales_5,0) AS CreditCard_Sales_5
		  ,COALESCE(t.CreditCard_Frequency_5,0) AS CreditCard_Frequency_5
		  ,COALESCE(t.CreditCard_Recency_5,140) AS CreditCard_Recency_5
		  ,COALESCE(t.Sales_6,0) AS Sales_6
		  ,COALESCE(t.Frequency_6,0) AS Frequency_6
		  ,COALESCE(t.Recency_6,168) AS Recency_6
		  ,COALESCE(t.MainBrand_Sales_6,0) AS MainBrand_Sales_6
		  ,COALESCE(t.MainBrand_Frequency_6,0) AS MainBrand_Frequency_6
		  ,COALESCE(t.MainBrand_Recency_6,168) AS MainBrand_Recency_6
		  ,COALESCE(t.Online_Sales_6,0) AS Online_Sales_6
		  ,COALESCE(t.Online_Frequency_6,0) AS Online_Frequency_6
		  ,COALESCE(t.Online_Recency_6,168) AS Online_Recency_6
		  ,COALESCE(t.CreditCard_Sales_6,0) AS CreditCard_Sales_6
		  ,COALESCE(t.CreditCard_Frequency_6,0) AS CreditCard_Frequency_6
		  ,COALESCE(t.CreditCard_Recency_6,168) AS CreditCard_Recency_6
		  ,COALESCE(t.Sales_13,0) AS Sales_13
		  ,COALESCE(t.Frequency_13,0) AS Frequency_13
		  ,COALESCE(t.Recency_13,364) AS Recency_13
		  ,COALESCE(t.MainBrand_Sales_13,0) AS MainBrand_Sales_13
		  ,COALESCE(t.MainBrand_Frequency_13,0) AS MainBrand_Frequency_13
		  ,COALESCE(t.MainBrand_Recency_13,364) AS MainBrand_Recency_13
		  ,COALESCE(t.Online_Sales_13,0) AS Online_Sales_13
		  ,COALESCE(t.Online_Frequency_13,0) AS Online_Frequency_13
		  ,COALESCE(t.Online_Recency_13,364) AS Online_Recency_13
		  ,COALESCE(t.CreditCard_Sales_13,0) AS CreditCard_Sales_13
		  ,COALESCE(t.CreditCard_Frequency_13,0) AS CreditCard_Frequency_13
		  ,COALESCE(t.CreditCard_Recency_13,364) AS CreditCard_Recency_13
		  ,COALESCE(m.MarketableByEmail,0) AS MarketableByEmail
		  ,COALESCE(ee.EmailOpenEvents_1Cycle,0) AS EmailOpenEvents_1Cycle
		  ,COALESCE(ee.EmailOpenEvents_2Cycle,0) AS EmailOpenEvents_2Cycle
		  ,COALESCE(ee.EmailOpenEvents_3Cycle,0) AS EmailOpenEvents_3Cycle
		  ,COALESCE(ee.EmailOpenEvents_6Cycle,0) AS EmailOpenEvents_6Cycle
		  ,COALESCE(wl.WebLogins_1Cycle,0) AS WebLogins_1Cycle
		  ,COALESCE(wl.WebLogins_2Cycle,0) AS WebLogins_2Cycle
		  ,COALESCE(wl.WebLogins_3Cycle,0) AS WebLogins_3Cycle
		  ,COALESCE(wl.WebLogins_6Cycle,0) AS WebLogins_6Cycle
		  ,@CampaignID
		FROM #CINID a
		LEFT JOIN #PersonalFeatures p
		  ON a.FanID = p.FanID
		LEFT JOIN #TransactionalFeatures t
		  ON a.FanID = t.FanID
		LEFT JOIN #Marketable m
		  ON a.FanID = m.FanID
		LEFT JOIN #EmailOpenEvents ee
		  ON a.FanID = ee.FanID
		LEFT JOIN #WebLogins wl
		  ON a.FanID = wl.FanID

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - Output', @time OUTPUT

	ALTER INDEX cix_FanID ON Warehouse.Prototype.Daz_PreCampaign_Features REBUILD
	ALTER INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_PreCampaign_Features REBUILD

	EXEC Warehouse.Prototype.oo_TimerMessage 'PreCampaign Features - End', @time OUTPUT

	/*

	-- Clear all previous entries
	TRUNCATE TABLE Warehouse.Prototype.Daz_PreCampaign_Features

	-- Delete specfic collection of entries
	DELETE FROM Warehouse.Prototype.Daz_PreCampaign_Features WHERE CampaignID = 1

	-- Recreate Table
	IF OBJECT_ID('Warehouse.Prototype.Daz_PreCampaign_Features') IS NOT NULL DROP TABLE Warehouse.Prototype.Daz_PreCampaign_Features
	CREATE TABLE Warehouse.Prototype.Daz_PreCampaign_Features
	(
		CINID int NULL,
		IronOfferID int NOT NULL,
		FanID int NOT NULL,
		GroupName VARCHAR(1) NOT NULL,
		StartDate date NULL,
		EndDate date NULL,
		Gender char(1) NULL,
		AgeCurrent tinyint NULL,
		HeatmapCameoGroup varchar(151) NULL,
		HeatmapScore float NULL,
		MinDriveTime float NULL,
		MinDriveDist float NULL,
		HasDD int NULL,
		HasCC int NULL,
		Sales_1 money NULL,
		Frequency_1 int NULL,
		Recency_1 int NULL,
		MainBrand_Sales_1 money NULL,
		MainBrand_Frequency_1 int NULL,
		MainBrand_Recency_1 int NULL,
		Online_Sales_1 money NULL,
		Online_Frequency_1 int NULL,
		Online_Recency_1 int NULL,
		CreditCard_Sales_1 money NULL,
		CreditCard_Frequency_1 int NULL,
		CreditCard_Recency_1 int NULL,
		Sales_2 money NULL,
		Frequency_2 int NULL,
		Recency_2 int NULL,
		MainBrand_Sales_2 money NULL,
		MainBrand_Frequency_2 int NULL,
		MainBrand_Recency_2 int NULL,
		Online_Sales_2 money NULL,
		Online_Frequency_2 int NULL,
		Online_Recency_2 int NULL,
		CreditCard_Sales_2 money NULL,
		CreditCard_Frequency_2 int NULL,
		CreditCard_Recency_2 int NULL,
		Sales_3 money NULL,
		Frequency_3 int NULL,
		Recency_3 int NULL,
		MainBrand_Sales_3 money NULL,
		MainBrand_Frequency_3 int NULL,
		MainBrand_Recency_3 int NULL,
		Online_Sales_3 money NULL,
		Online_Frequency_3 int NULL,
		Online_Recency_3 int NULL,
		CreditCard_Sales_3 money NULL,
		CreditCard_Frequency_3 int NULL,
		CreditCard_Recency_3 int NULL,
		Sales_4 money NULL,
		Frequency_4 int NULL,
		Recency_4 int NULL,
		MainBrand_Sales_4 money NULL,
		MainBrand_Frequency_4 int NULL,
		MainBrand_Recency_4 int NULL,
		Online_Sales_4 money NULL,
		Online_Frequency_4 int NULL,
		Online_Recency_4 int NULL,
		CreditCard_Sales_4 money NULL,
		CreditCard_Frequency_4 int NULL,
		CreditCard_Recency_4 int NULL,
		Sales_5 money NULL,
		Frequency_5 int NULL,
		Recency_5 int NULL,
		MainBrand_Sales_5 money NULL,
		MainBrand_Frequency_5 int NULL,
		MainBrand_Recency_5 int NULL,
		Online_Sales_5 money NULL,
		Online_Frequency_5 int NULL,
		Online_Recency_5 int NULL,
		CreditCard_Sales_5 money NULL,
		CreditCard_Frequency_5 int NULL,
		CreditCard_Recency_5 int NULL,
		Sales_6 money NULL,
		Frequency_6 int NULL,
		Recency_6 int NULL,
		MainBrand_Sales_6 money NULL,
		MainBrand_Frequency_6 int NULL,
		MainBrand_Recency_6 int NULL,
		Online_Sales_6 money NULL,
		Online_Frequency_6 int NULL,
		Online_Recency_6 int NULL,
		CreditCard_Sales_6 money NULL,
		CreditCard_Frequency_6 int NULL,
		CreditCard_Recency_6 int NULL,
		Sales_13 money NULL,
		Frequency_13 int NULL,
		Recency_13 int NULL,
		MainBrand_Sales_13 money NULL,
		MainBrand_Frequency_13 int NULL,
		MainBrand_Recency_13 int NULL,
		Online_Sales_13 money NULL,
		Online_Frequency_13 int NULL,
		Online_Recency_13 int NULL,
		CreditCard_Sales_13 money NULL,
		CreditCard_Frequency_13 int NULL,
		CreditCard_Recency_13 int NULL,
		MarketableByEmail bit NULL,
		EmailOpenEvents_1Cycle int NULL,
		EmailOpenEvents_2Cycle int NULL,
		EmailOpenEvents_3Cycle int NULL,
		EmailOpenEvents_6Cycle int NULL,
		WebLogins_1Cycle int NULL,
		WebLogins_2Cycle int NULL,
		WebLogins_3Cycle int NULL,
		WebLogins_6Cycle int NULL,
		CampaignID INT
	)

	CREATE CLUSTERED INDEX cix_FanID ON Warehouse.Prototype.Daz_PreCampaign_Features (FanID)
	CREATE NONCLUSTERED INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_PreCampaign_Features (FanID) INCLUDE (IronOfferID, CampaignID, GroupName)

	*/

END