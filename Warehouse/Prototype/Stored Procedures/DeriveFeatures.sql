-- =============================================
-- Author:		<Shaun H>
-- Create date: <28th Nov 2018>
-- Description:	<For a given group of @Customers, derive Personal, Transactional and Engagement Features>
-- =============================================
CREATE PROCEDURE Prototype.DeriveFeatures 
	(
		@CampaignStartDate DATE,
		@MainBrand	INT,
		@Sector	VARCHAR(200),
		@Customers VARCHAR(100)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	-- Pass the "customers" down from the parent script
	IF OBJECT_ID('tempdb..#FanID') IS NOT NULL DROP TABLE #FanID
	CREATE TABLE #FanID 
		(
			FanID INT
		)
	EXEC	('	
				INSERT INTO #FanID
					SELECT	FanID
					FROM	' + @Customers + '
			')

	CREATE CLUSTERED INDEX cix_FanID ON #FanID (FanID)

	-- Derive the date parameters
	DECLARE @PrePeriodStartDate DATE = DATEADD(DAY,-364,@CampaignStartDate)
	DECLARE @PrePeriodEndDate DATE = DATEADD(DAY,-1,@CampaignStartDate)
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
			SELECT	3 AS Cycles,
					DATEADD(DAY,-(27+2*28),@PrePeriodEndDate) AS StartDate,
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
		AND	p.BrandID = @MainBrand
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

	IF OBJECT_ID('tempdb..#PersonalFeatures') IS NOT NULL DROP TABLE #PersonalFeatures
	SELECT	d.FanID,
			d.Gender,
			d.AgeCurrent,
			d.HeatmapCameoGroup,
			COALESCE(hm.Index_RR,100) AS HeatmapScore,
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
						WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
						WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
						WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
						WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
						WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
						WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
					END AS HeatmapAgeGroup,
					ISNULL((cam.CAMEO_CODE_GROUP + '-' + camg.CAMEO_CODE_GROUP_Category),'99. Unknown') AS HeatmapCameoGroup
			FROM	Warehouse.Relational.Customer c WITH (NOLOCK)
			JOIN	#FanID f
				ON	c.FanID = f.FanID
			LEFT JOIN	Warehouse.Relational.CAMEO cam WITH (NOLOCK)
				ON	cam.postcode = c.postcode
			LEFT JOIN	Warehouse.Relational.Cameo_Code_Group camg WITH (NOLOCK)
				ON	camG.CAMEO_CODE_GROUP = cam.CAMEO_CODE_GROUP
		  ) d
	LEFT JOIN	Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2
		ON	d.Gender = lk2.gender 
		AND	d.HeatmapCameoGroup = lk2.CAMEO_grp 
		AND d.HeatmapAgeGroup=lk2.Age_Group
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index hm
		ON	lk2.ComboID = hm.ComboID
		AND	hm.BrandID = @MainBrand
	LEFT JOIN	#Proximity p
		ON	d.PostalSector = p.PostalSector
	LEFT JOIN	
		(	SELECT	pm.FanID,
					pm.PaymentMethodsAvailableID
			FROM	Warehouse.Relational.CustomerPaymentMethodsAvailable pm
			JOIN	#FanID f
				ON	pm.FanID = f.FanID
			WHERE	pm.StartDate <= @PrePeriodEndDate
				AND	(@PrePeriodEndDate < pm.EndDate OR pm.EndDate IS NULL) 
		) pm
		ON	d.FanID = pm.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #PersonalFeatures (FanID)

	/* END: Personal Features */

	------------------------------------------------------------------------------------
	/* START: Transactional Features */
	------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	BrandID,
			ConsumerCombinationID,
			CASE WHEN BrandID = @MainBrand THEN 1 ELSE 0 END AS MainBrand
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @Sector + ',') > 0
		OR	BrandID = @MainBrand

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ConsumerCombinationID ON #CC (ConsumerCombinationID) INCLUDE (MainBrand)

	IF OBJECT_ID('tempdb..#CINID') IS NOT NULL DROP TABLE #CINID
	SELECT	f.FanID,
			cin.CINID
	INTO	#CINID
	FROM	#FanID f
	JOIN	Warehouse.Relational.Customer c WITH (NOLOCK)
		ON	f.FanID = c.FanID
	JOIN	Warehouse.Relational.CINList cin WITH (NOLOCK)
		ON	c.SourceUID = cin.CIN

	CREATE CLUSTERED INDEX cix_CINID ON #CINID (CINID)
	CREATE NONCLUSTERED INDEX nix_FanID ON #CINID (FanID)

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

	IF OBJECT_ID('tempdb..#Pivoted') IS NOT NULL DROP TABLE #Pivoted
	CREATE TABLE #Pivoted
		(
			CINID_1	INT	,
			Cycles_1	INT	,
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
		SELECT	*,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
				NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
		FROM	#PrePivotTransactions
		WHERE	Cycles = 1

	UPDATE	o
	SET		-- 3 Month
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
			WHERE	Cycles = 3 ) ppt3
		ON	o.CINID_1 = ppt3.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 6 ) ppt6
		ON	o.CINID_1 = ppt6.CINID
	LEFT JOIN 
		(	SELECT	*
			FROM	#PrePivotTransactions
			WHERE	Cycles = 13 ) ppt13
		ON	o.CINID_1 = ppt13.CINID

	IF OBJECT_ID('tempdb..#TransactionalFeatures') IS NOT NULL DROP TABLE #TransactionalFeatures
	SELECT	FanID
			,CINID
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
		ON	a.CINID = b.CINID_1

	CREATE CLUSTERED INDEX cix_FanID ON #TransactionalFeatures (FanID)

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
	FROM	#FanID f
	JOIN	Warehouse.Relational.Customer_MarketableByEmailStatus m
		ON	f.FanID = m.FanID
	WHERE	StartDate < @CampaignStartDate
		AND	(EndDate IS NULL OR @CampaignStartDate <= EndDate )

	CREATE CLUSTERED INDEX cix_FanID ON #Marketable (FanID)

	-- EmailOpens

	IF OBJECT_ID('tempdb..#EmailOpenEvents') IS NOT NULL DROP TABLE #EmailOpenEvents
	SELECT	f.FanID,
			COUNT(CASE WHEN d.Cycles = 1 THEN EventID ELSE NULL END) AS EmailOpenEvents_1Cycle,
			COUNT(CASE WHEN d.Cycles = 6 THEN EventID ELSE NULL END) AS EmailOpenEvents_6Cycle
	INTO	#EmailOpenEvents
	FROM	#FanID f
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
	WHERE	d.Cycles IN (1,6)
		AND	ee.EmailEventCodeID IN (605,1301)
	GROUP BY f.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #EmailOpenEvents (FanID)

	-- WebLogins

	IF OBJECT_ID('tempdb..#WebLogins') IS NOT NULL DROP TABLE #WebLogins
	SELECT	f.FanID,
			COUNT(CASE WHEN d.Cycles = 1 THEN TrackDate ELSE NULL END) AS WebLogins_1Cycle,
			COUNT(CASE WHEN d.Cycles = 6 THEN TrackDate ELSE NULL END) AS WebLogins_6Cycle
	INTO	#WebLogins
	FROM	#FanID f
	JOIN	Warehouse.Relational.WebLogins wl
		ON	f.FanID = wl.FanID
	JOIN	#Dates d
		ON	d.StartDate <= wl.TrackDate AND wl.TrackDate < DATEADD(DAY,1,d.EndDate)
	WHERE	d.Cycles IN (1,6)
	GROUP BY f.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #WebLogins (FanID)

	/* END: Engagement Features */

	-------------------------------------------------------------------------------------------------------------
	/*	Output */
	-------------------------------------------------------------------------------------------------------------

	SELECT	f.FanID
			,p.Gender
			,p.AgeCurrent
			,p.HeatmapCameoGroup
			,p.HeatmapScore
			,p.MinDriveTime
			,p.MinDriveDist
			,p.HasDD
			,p.HasCC
			,t.Sales_1
			,t.Frequency_1
			,t.Recency_1
			,t.MainBrand_Sales_1
			,t.MainBrand_Frequency_1
			,t.MainBrand_Recency_1
			,t.Online_Sales_1
			,t.Online_Frequency_1
			,t.Online_Recency_1
			,t.CreditCard_Sales_1
			,t.CreditCard_Frequency_1
			,t.CreditCard_Recency_1
			,t.Sales_3
			,t.Frequency_3
			,t.Recency_3
			,t.MainBrand_Sales_3
			,t.MainBrand_Frequency_3
			,t.MainBrand_Recency_3
			,t.Online_Sales_3
			,t.Online_Frequency_3
			,t.Online_Recency_3
			,t.CreditCard_Sales_3
			,t.CreditCard_Frequency_3
			,t.CreditCard_Recency_3
			,t.Sales_6
			,t.Frequency_6
			,t.Recency_6
			,t.MainBrand_Sales_6
			,t.MainBrand_Frequency_6
			,t.MainBrand_Recency_6
			,t.Online_Sales_6
			,t.Online_Frequency_6
			,t.Online_Recency_6
			,t.CreditCard_Sales_6
			,t.CreditCard_Frequency_6
			,t.CreditCard_Recency_6
			,t.Sales_13
			,t.Frequency_13
			,t.Recency_13
			,t.MainBrand_Sales_13
			,t.MainBrand_Frequency_13
			,t.MainBrand_Recency_13
			,t.Online_Sales_13
			,t.Online_Frequency_13
			,t.Online_Recency_13
			,t.CreditCard_Sales_13
			,t.CreditCard_Frequency_13
			,t.CreditCard_Recency_13
			,m.MarketableByEmail
			,ee.EmailOpenEvents_1Cycle
			,ee.EmailOpenEvents_6Cycle
			,wl.WebLogins_1Cycle
			,wl.WebLogins_6Cycle
	FROM	#FanID f
	LEFT JOIN
		#PersonalFeatures p
		ON	f.FanID = p.FanID
	LEFT JOIN
		#TransactionalFeatures t
		ON	f.FanID = t.FanID
	LEFT JOIN	
		#Marketable m
		ON	f.FanID = m.FanID
	LEFT JOIN
		#EmailOpenEvents ee
		ON	f.FanID = ee.FanID
	LEFT JOIN
		#WebLogins wl
		ON	f.FanID = wl.FanID

	-------------------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------------------

END