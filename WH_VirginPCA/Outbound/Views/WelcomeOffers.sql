









/*
-- Author:		Ryan Dickson
-- Create date: 2020-07-22
-- Jira Ticket: 
-- Description:	View to return hydra offer id for virgin welcome offers
-- Change Log:
--				2020-07-22 - Initial Version.
--				2021-01-30 - Simplified Code
*/
CREATE VIEW [Outbound].[WelcomeOffers]
AS

SELECT	ID = NEWID()
	,	OfferGUID = iof.HydraOfferID
	,	CreatedAt = CONVERT(VARCHAR, GETDATE(), 126) + 'Z'
	,	UpdatedAt = CONVERT(VARCHAR, GETDATE(), 126) + 'Z'
--	,	OfferName = IronOfferName
FROM [Segmentation].[OfferWelcome] ow
INNER JOIN [Derived].[IronOffer] iof
	ON ow.IronOfferID = iof.IronOfferID

