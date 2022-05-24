-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Fetches CINs according to their offers
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_ExposedCINs_Fetch]
(
	@PartnerID INT
)
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
	WHERE iof.PartnerID	 = @PartnerID
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

    SELECT	DISTINCT
			cl.CINID
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



END