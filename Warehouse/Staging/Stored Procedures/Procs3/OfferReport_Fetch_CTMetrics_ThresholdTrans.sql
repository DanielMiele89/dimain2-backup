/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the transactions for Warehouse Mailed, Control and nfi Control customers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTMetrics_ThresholdTrans] 
	
AS
BEGIN
		
	SET NOCOUNT ON

    SELECT *
	   , SUM(Trans) OVER (PARTITION BY IronOfferID, StartDate, EndDate, Channel, Threshold, Exposed) TotalTrans 
    FROM Staging.OfferReport_ThresholdMetrics c

END