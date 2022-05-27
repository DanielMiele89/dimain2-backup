

CREATE VIEW [Derived].[IronOffer_Campaign_HTM]
AS

SELECT	PartnerID
	,	ClientServicesRef = MAX(ClientServicesRef)
	,	IronOfferID
FROM (
		SELECT	PartnerID
			,	ClientServicesRef
			,	IronOfferID
		FROM [Warehouse].[Relational].[IronOffer_Campaign_HTM]
		UNION
		SELECT	PartnerID
			,	ClientServicesRef
			,	IronOfferID
		FROM [nFI].[Relational].[IronOffer_Campaign_HTM]
		UNION
		SELECT	PartnerID
			,	ClientServicesRef
			,	IronOfferID
		FROM [WH_Virgin].[Derived].[IronOffer_Campaign_HTM]
		UNION
		SELECT	PartnerID
			,	ClientServicesRef
			,	IronOfferID
		FROM [WH_VirginPCA].[Derived].[IronOffer_Campaign_HTM]
		UNION
		SELECT	PartnerID
			,	ClientServicesRef
			,	IronOfferID
		FROM [WH_Visa].[Derived].[IronOffer_Campaign_HTM]) ht
GROUP BY	PartnerID
		,	IronOfferID