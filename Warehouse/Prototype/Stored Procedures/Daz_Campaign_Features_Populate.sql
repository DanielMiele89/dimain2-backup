-- =============================================
-- Author:		Shaun H.
-- Create date: 25th June 2019
-- Description:	Derive unincentivised and incentivised transactions, as well as engagement features for each customer in the corresponding exposed and control groups.
-- =============================================
CREATE PROCEDURE [Prototype].[Daz_Campaign_Features_Populate]
  @CampaignID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	-- Test rig
	-- DECLARE @CampaignID INT = 1

	DECLARE @time DATETIME
	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Start', @time OUTPUT

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

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #Exposed', @time OUTPUT

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

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #Control', @time OUTPUT

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

	DECLARE @PartnerID INT,
			@StartDate DATE,
			@EndDate DATE
	
	SELECT
	  @PartnerID = MIN(PartnerID),
	  @StartDate = MIN(StartDate),
	  @EndDate = MIN(EndDate)
	FROM #IronOffer

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT 
	  BrandID,
	  ConsumerCombinationID
	INTO #CC
	FROM Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	WHERE EXISTS
		( SELECT 1
		  FROM Warehouse.Relational.Partner p
		  WHERE	PartnerID = @PartnerID
			AND cc.BrandID = p.BrandID )

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#CampaignTransactions') IS NOT NULL DROP TABLE #CampaignTransactions
	SELECT
		ct.CINID,
		SUM(ct.Amount) AS Sales,
		COUNT(ct.Amount) AS Transactions,
		SUM(CASE WHEN c.MinimumBasketSize <= ct.Amount THEN ct.Amount ELSE 0 END) AS AboveThreshold_Sales,
		COUNT(CASE WHEN c.MinimumBasketSize <= ct.Amount THEN ct.Amount ELSE NULL END) AS AboveThreshold_Transactions
	INTO #CampaignTransactions
	FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
	JOIN #CC cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	JOIN #CINID c
		ON ct.CINID = c.CINID
	WHERE @StartDate <= ct.TranDate AND ct.TranDate <= @EndDate
	GROUP BY
		ct.CINID

	CREATE CLUSTERED INDEX cix_CINID ON #CampaignTransactions (CINID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - All Transactions', @time OUTPUT

	IF OBJECT_ID('tempdb..#PartnerTransactions') IS NOT NULL DROP TABLE #PartnerTransactions
	SELECT
		pt.FanID,
		SUM(pt.TransactionAmount) AS Sales,
		COUNT(pt.TransactionAmount) AS Transactions,
		SUM(CASE WHEN c.MinimumBasketSize <= pt.TransactionAmount THEN pt.TransactionAmount ELSE 0 END) AS AboveThreshold_Sales,
		COUNT(CASE WHEN c.MinimumBasketSize <= pt.TransactionAmount THEN pt.TransactionAmount ELSE NULL END) AS AboveThreshold_Transactions,
		SUM(CashbackEarned) AS Cashback,
		SUM(CommissionChargable) AS Investment,
		SUM(CASE WHEN c.MinimumBasketSize < pt.TransactionAmount THEN CashbackEarned ELSE 0 END) AS AboveThreshold_Cashback,
		SUM(CASE WHEN c.MinimumBasketSize < pt.TransactionAmount THEN CommissionChargable ELSE 0 END) AS AboveThreshold_Investment
	INTO #PartnerTransactions
	FROM Warehouse.Relational.PartnerTrans pt WITH (NOLOCK)
	JOIN #CINID c
		ON pt.FanID = c.FanID
	WHERE @StartDate <= pt.TransactionDate AND pt.TransactionDate <= @EndDate
		AND PartnerID = @PartnerID
	GROUP BY
		pt.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #PartnerTransactions (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Incentivised Transactions', @time OUTPUT

	IF OBJECT_ID('tempdb..#Campaign') IS NOT NULL DROP TABLE #Campaign
	SELECT
	  a.*,
	  COALESCE(b.Sales,0) AS Campaign_Sales,
	  COALESCE(b.Transactions,0) AS Campaign_Transactions,
	  COALESCE(b.AboveThreshold_Sales,0) as Campaign_AboveThreshold_Sales,
	  COALESCE(b.AboveThreshold_Transactions,0) AS Campaign_AboveThreshold_Transactions,
	  COALESCE(c.Sales,0) AS Incentivised_Sales,
	  COALESCE(c.Transactions,0) AS Incentivised_Transactions,
	  COALESCE(c.AboveThreshold_Sales,0) AS Incentivised_AboveThreshold_Sales,
	  COALESCE(c.AboveThreshold_Transactions,0) AS Incentivised_AboveThreshold_Transactions,
	  COALESCE(c.Cashback,0) AS Incentivised_Cashback,
	  COALESCE(c.Investment,0) AS Incentivised_Investment,
	  COALESCE(c.AboveThreshold_Cashback,0) AS Incentivised_AboveThreshold_Cashback,
	  COALESCE(c.AboveThreshold_Investment,0) AS Incentivised_AboveThreshold_Investment
	INTO #Campaign
	FROM #CINID a
	LEFT JOIN #CampaignTransactions AS b
	  ON a.CINID = b.CINID
	LEFT JOIN #PartnerTransactions c
	  ON a.FanID = c.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #Campaign (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Campaign Transactions Output', @time OUTPUT

	---------------------------------------------------------------------------------------------------------
	-- Engagement Features
	---------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Marketable') IS NOT NULL DROP TABLE #Marketable
	SELECT
	  a.FanID,
	  a.MarketableByEmail
	INTO #Marketable
	FROM Warehouse.Relational.Customer_MarketableByEmailStatus a
	JOIN #CINID c
	  ON a.FanID = c.FanID
	WHERE a.StartDate < @StartDate
	  AND (a.EndDate IS NULL OR @StartDate <= a.EndDate)

	CREATE CLUSTERED INDEX cix_FanID ON #Marketable (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #Marketable', @time OUTPUT

	IF OBJECT_ID('tempdb..#ServedOffer') IS NOT NULL DROP TABLE #ServedOffer
	SELECT
	  l.FanID,
	  l.ItemID AS IronOfferID,
	  l.OfferSlot
	INTO #ServedOffer
	FROM Warehouse.Lion.LionSend_Offers l
	WHERE TypeID = 1
	  AND EXISTS 
		( SELECT 1
		  FROM #IronOffer o
		  WHERE l.ItemID = o.IronOfferID )

	CREATE CLUSTERED INDEX cix_FanID ON #ServedOffer (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #ServedOffer', @time OUTPUT

	IF OBJECT_ID('tempdb..#EmailOpens') IS NOT NULL DROP TABLE #EmailOpens
	SELECT
	  ee.FanID,
	  COUNT(*) AS EmailInteractions,
	  COUNT(DISTINCT ee.CampaignKey) AS CampaignOpens
	INTO #EmailOpens
	FROM Warehouse.Relational.EmailEvent ee
	JOIN
	(
	  SELECT
		DISTINCT CampaignKey
	  FROM Warehouse.Relational.EmailCampaign
	  WHERE CampaignName LIKE '%NEWSLETTER%'
		AND CampaignName NOT LIKE '%COPY%' 
		AND CampaignName NOT LIKE '%TEST%'
	) cls -- List of Newsletter emails
	ON ee.CampaignKey = cls.CampaignKey
	JOIN #CINID c
	  ON ee.FanID = c.FanID
	WHERE
	  ee.EmailEventCodeID IN (1301, -- Email Open
							  605)  -- Link Click
	  AND @StartDate <= EventDate AND EventDate <= @EndDate
	GROUP BY
	  ee.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #EmailOpens (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #EmailOpens', @time OUTPUT

	IF OBJECT_ID('tempdb..#WebLogins') IS NOT NULL DROP TABLE #WebLogins
	SELECT
	  a.FanID AS FanID,
	  COUNT(TrackDate) AS WebLogins,
	  COUNT(DISTINCT CAST(TrackDate AS DATE)) AS WebLoginDays
	INTO #WebLogins
	FROM Warehouse.Relational.WebLogins a
	JOIN #CINID c
	  ON a.fanid = c.FanID
	WHERE (@StartDate <= TrackDate AND TrackDate <= @EndDate)
	GROUP BY
	  a.FanID

	CREATE CLUSTERED INDEX cix_FanID ON #WebLogins (FanID)

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #WebLogins', @time OUTPUT


	IF OBJECT_ID('tempdb..#Campaign_Plus_Engagement') IS NOT NULL DROP TABLE #Campaign_Plus_Engagement
	SELECT 
	  a.*,
	  COALESCE(b.MarketableByEmail,0) AS MarketableByEmail,
	  CASE
		WHEN c.FanID IS NOT NULL THEN 1
		ELSE 0
	  END AS ServedOffer,
	  COALESCE(c.OfferSlot,0) AS OfferSlot,
	  COALESCE(d.EmailInteractions,0) AS EmailInteractions,
	  COALESCE(d.CampaignOpens,0) AS CampaignOpens,
	  COALESCE(e.WebLogins,0) AS WebLogins,
	  COALESCE(e.WebLoginDays,0) AS WebLoginDays
	INTO #Campaign_Plus_Engagement
	FROM #Campaign a
	LEFT JOIN #Marketable b
	  ON a.FanID = b.FanID
	LEFT JOIN #ServedOffer c
	  ON a.FanID = c.FanID
	LEFT JOIN #EmailOpens d
	  ON a.FanID = d.FanID
	LEFT JOIN #WebLogins e
	  ON a.FanID = e.FanID

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - #Output', @time OUTPUT

	ALTER INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_Campaign_Features DISABLE

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Disable Indexes', @time OUTPUT

	INSERT INTO Warehouse.Prototype.Daz_Campaign_Features
	  SELECT 
	    *,
	    @CampaignID AS CampaignID
	  FROM #Campaign_Plus_Engagement

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Insert', @time OUTPUT

	ALTER INDEX cix_FanID ON Warehouse.Prototype.Daz_Campaign_Features REBUILD
	ALTER INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_Campaign_Features REBUILD

	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - Rebuild Indexes', @time OUTPUT


	EXEC Warehouse.Prototype.oo_TimerMessage 'Campaign Features - End', @time OUTPUT

	/*

	-- Clear all previous entries
	TRUNCATE TABLE Warehouse.Prototype.Daz_Campaign_Features

	-- Delete specfic collection of entries
	DELETE FROM Warehouse.Prototype.Daz_Campaign_Features WHERE CampaignID = 1

	-- Recreate Table
	IF OBJECT_ID('Warehouse.Prototype.Daz_Campaign_Features') IS NOT NULL DROP TABLE Warehouse.Prototype.Daz_Campaign_Features
	CREATE TABLE Warehouse.Prototype.Daz_Campaign_Features
	(
		IronOfferID INT,
		FanID INT,
		StartDate DATE,
		EndDate DATE,
		GroupName VARCHAR(1),
		CINID INT,
		BelowThresholdRate FLOAT,
		MinimumBasketSize FLOAT,
		AboveThresholdRate FLOAT,
		Campaign_Sales MONEY,
		Campaign_Transactions INT,
		Campaign_AboveThreshold_Sales MONEY,
		Campaign_AboveThreshold_Transactions INT,
		Incentivised_Sales MONEY,
		Incentivised_Transactions INT,
		Incentivised_AboveThreshold_Sales MONEY,
		Incentivised_AboveThreshold_Transactions INT,
		Incentivised_Cashback MONEY,
		Incentivised_Investment MONEY,
		Incentivised_AboveThreshold_Cashback MONEY,
		Incentivised_AboveThreshold_Investment MONEY,
		MarketableByEmail INT,
		ServedOffer INT,
		OfferSlot INT,
		EmailInteractions INT,
		CampaignOpens INT,
		WebLogins INT,
		WebLoginDays INT,
		CampaignID INT
	)

	CREATE CLUSTERED INDEX cix_FanID ON Warehouse.Prototype.Daz_Campaign_Features (FanID)
	CREATE NONCLUSTERED INDEX nix_FanID__IronOfferID_CampaignID ON Warehouse.Prototype.Daz_Campaign_Features (FanID) INCLUDE (IronOfferID, CampaignID, GroupName)

	*/

END
