-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Fetches CINs according to their offers
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RawExposedData_Load]
AS
BEGIN

	SET NOCOUNT ON;

	--DECLARE @PartnerID INT = 4263

	DECLARE @MonthDate DATE, @MonthEndDate DATE
	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) -- First day of the last completed month
	SET @MonthEndDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @MonthDate))

	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
	SELECT	iof.IronOfferID
	INTO #IronOffer
	FROM [Relational].[IronOffer] iof
	WHERE EXISTS (	SELECT 1
					FROM [APW].[ControlRetailers] cr
					WHERE iof.PartnerID = cr.PartnerID)
	AND (iof.EndDate IS NULL OR @MonthDate < iof.EndDate)
	AND iof.StartDate <= @MonthEndDate

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer (IronOfferID)

	IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
	SELECT	iom.CompositeID
	INTO #IronOfferMember
	FROM [Relational].[IronOfferMember] iom
	WHERE iom.EndDate IS NULL
	AND iom.StartDate <= @MonthEndDate
	AND EXISTS (	SELECT 1
					FROM #IronOffer iof
					WHERE iom.IronOfferID = iof.IronOfferID)
	UNION ALL
	SELECT	iom.CompositeID
	FROM [Relational].[IronOfferMember] iom
	WHERE @MonthDate < iom.EndDate
	AND iom.StartDate <= @MonthEndDate
	AND EXISTS (	SELECT 1
					FROM #IronOffer iof
					WHERE iom.IronOfferID = iof.IronOfferID)

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOfferMember (CompositeID)
	
	IF OBJECT_ID('tempdb..#ExposedCINs') IS NOT NULL DROP TABLE #ExposedCINs
    SELECT	DISTINCT
			cl.CINID
	INTO #ExposedCINs
	FROM [Relational].[Customer] cu
	INNER JOIN [Relational].[CINList] cl
		ON cu.SourceUID = cl.CIN
	WHERE cu.ActivatedDate < @MonthDate
	AND cu.CurrentlyActive = 1
	AND NOT EXISTS (SELECT 1
					FROM [MI].[CINDuplicate] cd
					WHERE cu.FanID = cd.FanID)
	AND EXISTS (	SELECT 1
					FROM #IronOfferMember iom
					WHERE cu.CompositeID = iom.CompositeID)

	CREATE CLUSTERED INDEX CIX_CC ON #ExposedCINs (CINID)



	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.ConsumerCombinationID
	INTO #CC
	FROM [Relational].[ConsumerCombination] cc
	WHERE EXISTS (	SELECT 1
					FROM [APW].[ControlRetailers] cr
					WHERE cc.BrandID = cr.BrandID)

	CREATE CLUSTERED INDEX CIX_CC ON #CC (ConsumerCombinationID)



	DECLARE @StartDate DATE, @EndDate DATE

	SET @StartDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @EndDate = DATEADD(DAY, -1, @StartDate)
	SET @StartDate = DATEADD(YEAR, -1, @StartDate)
	

	
	TRUNCATE TABLE [APW].[SpendPurchaseCount_CT_Exposed]

	INSERT INTO [APW].[SpendPurchaseCount_CT_Exposed]
	SELECT	ca.CINID
		,	ct.ConsumerCombinationID
		,	COUNT(*) AS TranCount
		,	SUM(ct.Amount) AS Spend
	FROM [Relational].[ConsumerTransaction] ct
	INNER JOIN #ExposedCINs ca
		ON ct.CINID = ca.CINID
	INNER JOIN #CC cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY	ca.CINID
			,	ct.ConsumerCombinationID

	ALTER INDEX CIX_CINCC ON [APW].[SpendPurchaseCount_CT_Exposed] REBUILD WITH (DATA_COMPRESSION = ROW, SORT_IN_TEMPDB = ON)

END