/******************************************************************************
PROCESS NAME: Offer Calculation - Clear Staging Tables

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Empties staging tables

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

18/12/2018 Jason Shipp
- Added truncation of [Report].[IronOfferSegment] table so that it can be refreshed

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Clear_Staging] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE [Report].[OfferReport_AllOffers]
	TRUNCATE TABLE [Report].[OfferReport_AllOffers_Errors]
	TRUNCATE TABLE [Report].[OfferReport_ConsumerCombinations]
	TRUNCATE TABLE [Report].[OfferReport_CTCustomers]
	TRUNCATE TABLE [Report].[OfferReport_MatchTrans]
	TRUNCATE TABLE [Report].[OfferReport_ThresholdMetrics]
	TRUNCATE TABLE [Report].[OfferReport_Metrics]

	TRUNCATE TABLE [Report].[OfferReport_Cardholders]
	TRUNCATE TABLE [Report].[OfferReport_MatchCustomers]
	TRUNCATE TABLE [Report].[OfferReport_Metrics_CustGroup]

END



