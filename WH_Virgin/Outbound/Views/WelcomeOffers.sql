






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
SELECT
	oca.HydraOfferID
FROM 
	[Segmentation].[OfferWelcome] ow
INNER JOIN
	[DIMAIN_TR].[SLC_REPL].hydra.[OfferConverterAudit] oca
ON
	ow.IronOfferID = oca.IronOfferId
INNER JOIN
	[DIMAIN_TR].[SLC_REPL].dbo.IronOffer io
ON
	ow.IronOfferID = io.ID
INNER JOIN
	[DIMAIN_TR].[SLC_REPL].dbo.IronOfferClub ioc
ON
	io.ID = ioc.IronOfferID
WHERE
	ioc.ClubID = 166
AND
	io.IsSignedOff = 1
