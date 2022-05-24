
/*
-- Author:		Ryan Dickson
-- Create date: 2020-07-23
-- Jira Ticket: 
-- Description:	View to return segmented offers to virgin
-- Change Log:
--				2020-07-23 - Initial Version.
--				2021-02-16 - OfferProcessLog logic added to view
*/

CREATE VIEW [Outbound].[SegmentedOfferAdditions]
AS

SELECT	CustomerID = cu.CustomerGUID
	,	HydraOfferID = iof.HydraOfferID
	,	StartDate = ow.StartDate
	,	EndDate = ow.EndDate
FROM [Segmentation].[OfferMemberAddition] ow
INNER JOIN [Segmentation].[OfferProcessLog] opl
	ON ow.IronOfferID = opl.IronOfferID
INNER JOIN [Derived].[Customer] cu
	ON cu.CompositeID = ow.CompositeID
INNER JOIN [Derived].[IronOffer] iof
	ON ow.IronOfferID = iof.IronOfferID
WHERE iof.ClubID = 180
AND iof.IsSignedOff = 1
AND opl.IsUpdate = 0
AND opl.Processed = 0
AND opl.SignedOff = 1

