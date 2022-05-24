
CREATE PROCEDURE [Selections].[CampaignExecution_GenerateSegmentationFile]
AS
BEGIN

	--DROP TABLE Sandbox.Rory.OfferMemberAddition_Visa
	SELECT	NEWID() AS ID
		,	cu.CustomerGUID
		,	iof.HydraOfferID
		,	convert(varchar, oma.StartDate, 126) + '.000Z' AS StartDate
		,	convert(varchar, oma.EndDate, 126) + '.000Z' AS EndDate
	--INTO Sandbox.Rory.OfferMemberAddition_Visa
	FROM [Segmentation].[OfferMemberAddition] oma
	INNER JOIN [Derived].[IronOffer] iof
		ON oma.IronOfferID = iof.IronOfferID
	INNER JOIN [WHB].[Customer] cu
		ON oma.CompositeID = cu.CompositeID
	WHERE EXISTS (	SELECT 1
					FROM [Segmentation].[OfferProcessLog] opl
					WHERE oma.IronOfferID = opl.IronOfferID
					AND opl.Processed = 0)

END