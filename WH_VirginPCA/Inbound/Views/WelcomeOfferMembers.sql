


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
,	ow.LoadDate
FROM 
	[WH_VirginPCA].[Inbound].[WelcomeIronOfferMembers] ow
INNER JOIN
	[Derived].[Customer] f
ON
	f.CustomerGUID = ow.CustomerGUID
AND
	f.ClubID = 182 --added to ensure its only virgin records and SourceUID is not unique
INNER JOIN
(
	SELECT
		io.HydraOfferID
	,	ppl.HydraPartnerID
	,	MAX(io.PartnerID) AS PartnerID
	,	MAX(io.IronOfferID) AS IronOfferID
	FROM
		[Derived].[IronOffer] io
	INNER JOIN
		SLC_REPL.hydra.[PartnerPublisherLink] ppl
	ON
		io.PartnerID = ppl.PartnerID
	WHERE
		io.ClubID = 182
	AND
		io.IsSignedOff = 1
	GROUP BY
		io.HydraOfferID
	,	ppl.HydraPartnerID
) offers
ON
	ow.OfferGUID = offers.HydraOfferID
