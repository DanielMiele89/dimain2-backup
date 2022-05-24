

CREATE PROCEDURE [Segmentation].[Segmentation_FileGeneration] 

as

SET NOCOUNT ON

SELECT	NEWID() AS ID
		,	cu.CustomerGUID
		,	iof.HydraOfferID
		,	convert(varchar, oma.StartDate, 126) + '.000Z' AS StartDate
		,	convert(varchar, oma.EndDate, 126) + '.000Z' AS EndDate
	FROM wh_Visa.[Segmentation].[OfferMemberAddition] oma
	INNER JOIN wh_Visa.[Derived].[IronOffer] iof
		ON oma.IronOfferID = iof.IronOfferID
	INNER JOIN wh_Visa.[WHB].[Customer] cu
		ON oma.CompositeID = cu.CompositeID
	ORDER BY oma.StartDate


