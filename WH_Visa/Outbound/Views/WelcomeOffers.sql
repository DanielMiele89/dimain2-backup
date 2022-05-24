







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
SELECT	OfferGUID = iof.HydraOfferID
FROM [Segmentation].[OfferWelcome] ow
INNER JOIN [Derived].[IronOffer] iof
	ON ow.IronOfferID = iof.IronOfferId

