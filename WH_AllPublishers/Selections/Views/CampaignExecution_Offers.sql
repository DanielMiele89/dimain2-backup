
CREATE VIEW [Selections].[CampaignExecution_Offers]
AS

SELECT	ClubID
	,	ClubName
	,	PartnerID
	,	PartnerName
	,	IronOfferID
	,	IronOfferName
	,	StartDate
	,	EndDate
FROM (	SELECT	ClubID = o.PublisherID
			,	ClubName =	CASE
								WHEN o.PublisherID = 180 THEN 'Visa Barclaycard'
								WHEN o.PublisherID = 182 THEN 'Virgin PCA'
								WHEN o.PublisherID = 166 THEN 'Virgin CC'
								WHEN o.PublisherID = 132 THEN 'MyRewards'
								ELSE pu.PublisherName
							END
			,	PartnerID = o.PartnerID
			,	PartnerName = pa.PartnerName
			,	IronOfferID = o.IronOfferID
			,	IronOfferName = COALESCE(iof.Name, o.OfferName)
			,	StartDate = COALESCE(iof.StartDate, o.StartDate)
			,	EndDate = COALESCE(iof.EndDate, o.EndDate)
		FROM [WH_AllPublishers].[Derived].[Offer] o
		INNER JOIN [WH_AllPublishers].[Derived].[Publisher] pu
			ON o.PublisherID = pu.PublisherID
		INNER JOIN [WH_AllPublishers].[Derived].[Partner] pa
			ON o.PartnerID = pa.PartnerID
		LEFT JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
			ON o.IronOfferID = iof.ID
		WHERE o.PublisherType = 'Bank Scheme'
		UNION
		SELECT	ClubID = ioc.ClubID
			,	ClubName =	CASE
								WHEN ioc.ClubID = 182 THEN 'Visa Barclaycard'
								WHEN ioc.ClubID = 182 THEN 'Virgin PCA'
								WHEN ioc.ClubID = 166 THEN 'Virgin CC'
								WHEN ioc.ClubID = 132 THEN 'MyRewards'
								ELSE cl.Name
							END
			,	PartnerID = iof.PartnerID
			,	PartnerName = pa.Name
			,	IronOfferID = iof.ID
			,	IronOfferName = iof.Name
			,	StartDate = iof.StartDate
			,	EndDate = iof.EndDate
		FROM [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[IronOfferClub] ioc
			ON iof.ID = ioc.IronOfferID
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Club] cl
			ON ioc.ClubID = cl.ID
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Partner] pa
			ON iof.PartnerID = pa.ID
		WHERE NOT EXISTS (	SELECT 1
							FROM [WH_AllPublishers].[Derived].[Offer] o
							WHERE iof.ID = o.IronOfferID)
		AND EXISTS (		SELECT 1
							FROM [WH_AllPublishers].[Derived].[Publisher] p
							WHERE ioc.ClubID = p.PublisherID
							AND p.PublisherType = 'Bank Scheme'
							AND p.PublisherID != 138)) o
WHERE o.IronOfferName NOT LIKE '%GT016%'
AND IronOfferName NOT LIKE '%VIR001%'
AND IronOfferName NOT LIKE '%Cli016%'

