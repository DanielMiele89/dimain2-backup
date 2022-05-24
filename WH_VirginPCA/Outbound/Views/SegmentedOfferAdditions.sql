








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
SELECT
	f.SourceUID AS CustomerID
,	oca.HydraOfferID
,	ow.StartDate
,	ow.EndDate
FROM 
	[Segmentation].[OfferMemberAddition] ow
INNER JOIN
	[Segmentation].[OfferProcessLog] opl
ON
	ow.IronOfferID = opl.IronOfferID
INNER JOIN
	SLC_REPL.dbo.Fan f
ON
	f.CompositeID = ow.CompositeID
INNER JOIN
	SLC_REPL.hydra.[OfferConverterAudit] oca
ON
	ow.IronOfferID = oca.IronOfferId
INNER JOIN
	SLC_REPL.dbo.IronOffer io
ON
	ow.IronOfferID = io.ID
INNER JOIN
	SLC_REPL.dbo.IronOfferClub ioc
ON
	io.ID = ioc.IronOfferID
WHERE
	ioc.ClubID = 166
AND
	io.IsSignedOff = 1
AND
	opl.IsUpdate = 0
AND
	opl.Processed = 0
AND
	opl.SignedOff = 1
