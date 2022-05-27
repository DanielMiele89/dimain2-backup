/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_ConsumerTransaction]

AS
BEGIN

	DECLARE @StartDate DATETIME
		,	@EndDate DATETIME

	SELECT	@StartDate = MIN(StartDate)
		,	@EndDate = MAX(EndDate)
	FROM [Report].[OfferReport_AllOffers]

	ALTER INDEX [UCX_SourceRetailerCC] ON [Report].[OfferReport_ConsumerCombinations] REBUILD WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)
		
	IF OBJECT_ID('[Report].[OfferReport_ConsumerTransaction]') IS NOT NULL DROP TABLE [Report].[OfferReport_ConsumerTransaction]
	SELECT	ct.DataSource
		,	cc.RetailerID
		,	cc.PartnerID
		,	cc.MID
		,	ct.ConsumerCombinationID
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
		,	ct.TranDate
	INTO [Report].[OfferReport_ConsumerTransaction]
	FROM [Trans].[ConsumerTransaction] ct
	INNER JOIN [Report].[OfferReport_ConsumerCombinations] cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		AND ct.DataSource = cc.DataSource
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Report].[OfferReport_CTCustomers] cu
					WHERE ct.CINID = cu.CINID)
					
	CREATE CLUSTERED INDEX CIX_CCID ON [Report].[OfferReport_ConsumerTransaction] (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX IX_CINID ON [Report].[OfferReport_ConsumerTransaction] (CINID)
	CREATE NONCLUSTERED INDEX IX_CCDateAmount_IncCIN ON [Report].[OfferReport_ConsumerTransaction] ([ConsumerCombinationID],[TranDate],[Amount]) INCLUDE ([CINID])

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON [Report].[OfferReport_ConsumerTransaction] (CINID, ConsumerCombinationID, Amount, TranDate, IsOnline)

END