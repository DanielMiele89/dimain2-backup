/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Load_ConsumerTransaction_20210310]

AS
BEGIN

	DECLARE @StartDate DATETIME
		,	@EndDate DATETIME

	SELECT	@StartDate = MIN(StartDate)
		,	@EndDate = MAX(EndDate)
	FROM [Staging].[OfferReport_AllOffers]

	ALTER INDEX [IX_CC] ON [Staging].[OfferReport_ConsumerCombinations] REBUILD WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE)

	IF OBJECT_ID('[Staging].[OfferReport_ConsumerTransaction]') IS NOT NULL DROP TABLE [Staging].[OfferReport_ConsumerTransaction]
	SELECT	ct.ConsumerCombinationID
		,	ct.TranDate
		,	ct.CINID
		,	ct.Amount
		,	ct.IsOnline
	INTO [Staging].[OfferReport_ConsumerTransaction]
	FROM [Relational].[ConsumerTransaction] ct
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (	SELECT 1
					FROM [Staging].[OfferReport_ConsumerCombinations] cc
					WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)

	CREATE NONCLUSTERED COLUMNSTORE INDEX CSI_All ON [Warehouse].[Staging].[OfferReport_ConsumerTransaction] (CINID, ConsumerCombinationID, Amount, TranDate, IsOnline) ON Warehouse_Columnstores

END