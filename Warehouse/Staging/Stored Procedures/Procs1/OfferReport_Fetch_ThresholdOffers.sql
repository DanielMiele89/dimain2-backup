/******************************************************************************
Author	  Hayden Reid
Created	  31/07/2017
Purpose	  Gets list of offers to be input into Spend Stretch loop

Copyright © 2017, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

Jason Shipp 02/08/2018
	- Added check to ensure only IDs for which threshold customer transactions, that have not yet been loaded into Warehouse.Staging.OfferReport_ThresholdMetrics, are fetched

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ThresholdOffers]
AS
	   
BEGIN
 
    SELECT o.ID
    FROM Staging.OfferReport_Alloffers o
    LEFT JOIN Staging.OfferReport_ThresholdMetrics t
	   ON t.IronOfferID = o.IronOfferID
	   AND t.StartDate = o.StartDate
	   AND t.EndDate = o.EndDate
    WHERE o.SpendStretch IS NOT NULL
	   AND o.isWarehouse IS NOT NULL
	   AND o.isVirgin IS NOT NULL
	   AND o.isVisaBarclaycard IS NOT NULL
	   AND t.CINID IS NULL
	AND NOT EXISTS (
		SELECT DISTINCT a.ID from Staging.OfferReport_ThresholdMetrics m
		INNER JOIN Staging.OfferReport_Alloffers a 
		   ON a.IronOfferID = m.IronOfferID
		   AND a.StartDate = m.StartDate
		   AND a.EndDate = m.EndDate
		   AND a.ControlGroupID = m.ControlGroupID
		   AND (a.IronOfferCyclesID = m.IronOfferCyclesID OR a.IronOfferCyclesID IS NULL AND m.IronOfferCyclesID IS NULL)
		   AND (a.isWarehouse = m.isWarehouse OR a.isWarehouse IS NULL AND m.isWarehouse IS NULL)
		WHERE a.ID = o.ID
	)
    ORDER BY o.ID;

END