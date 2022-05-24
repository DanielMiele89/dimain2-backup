









/*
-- Author:		Ryan Dickson
-- Create date: 2020-07-23
-- Jira Ticket: 
-- Description:	View to return welcome offer members from Virgin
-- Change Log:
--				2020-07-23 - Initial Version.
*/
CREATE VIEW [Inbound].[WelcomeOfferMembers]
AS
SELECT
	offers.IronOfferID
,	f.CompositeID
,	ow.StartDate
,	ow.EndDate
,	ow.ImportDate
FROM 
	[WH_Virgin].[Inbound].[WelcomeIronOfferMembers] ow
INNER JOIN
	[DIMAIN_TR].[SLC_REPL].[dbo].[Fan] f
ON
	f.SourceUID = ow.SourceUID
AND
	f.ClubID = 166 --added to ensure its only virgin records and SourceUID is not unique
INNER JOIN
(
	SELECT
		oca.HydraOfferID
	,	ppl.HydraPartnerID
	,	MAX(io.PartnerID) AS PartnerID
	,	MAX(io.ID) AS IronOfferID
	FROM
		[DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] io
	INNER JOIN
		SLC_REPL.dbo.IronOfferClub ioc
	ON
		io.ID = ioc.IronOfferID
	INNER JOIN
		[DIMAIN_TR].[SLC_REPL].hydra.[OfferConverterAudit] oca
	ON
		io.ID = oca.IronOfferId
	INNER JOIN
		[DIMAIN_TR].[SLC_REPL].hydra.[PartnerPublisherLink] ppl
	ON
		io.PartnerID = ppl.PartnerID
	WHERE
		ioc.ClubID = 166
	AND
		ppl.HydraPublisherID = 'fac15ab5-3f9f-4501-8bff-488c11685839'
	AND
		io.IsSignedOff = 1
	GROUP BY
		oca.HydraOfferID
	,	ppl.HydraPartnerID
) offers
ON
	ow.HydraOfferID = offers.HydraOfferID
