CREATE PROCEDURE Outbound.SegmentedOfferAdditions_Fetch
AS
BEGIN

	IF OBJECT_ID('tempdb..#Fans') IS NOT NULL
		DROP TABLE #Fans

	SELECT 
		f.CompositeID
		, f.SourceUID
	INTO #Fans
	FROM DIMAIN_TR.SLC_REPL.dbo.Fan f
	WHERE f.ClubID = 166

	CREATE CLUSTERED INDEX CIX ON #Fans (CompositeID)

	SELECT
		f.SourceUID AS CustomerID
		, #Fans.[x].HydraOfferID
		, ow.StartDate
		, ow.EndDate
	FROM [Segmentation].[OfferMemberAddition] ow
	INNER JOIN [Segmentation].[OfferProcessLog] opl
	ON ow.IronOfferID = opl.IronOfferID
	JOIN #Fans f
		ON ow.CompositeID = f.CompositeID
	INNER JOIN OPENQUERY(DIMAIN_TR,
		'SELECT oca.IronOfferId, oca.HydraOfferID
		FROM [SLC_REPL].hydra.[OfferConverterAudit] oca
		INNER JOIN [SLC_REPL].dbo.IronOffer io
		ON oca.IronOfferID = io.ID
		INNER JOIN [SLC_REPL].dbo.IronOfferClub ioc
		ON io.ID = ioc.IronOfferID
		WHERE ioc.ClubID = 166
		AND io.IsSignedOff = 1'
	) x
		ON #Fans.[x].IronOfferID = ow.IronOfferID
	WHERE opl.IsUpdate = 0
		AND opl.Processed = 0
		AND opl.SignedOff = 1

END
