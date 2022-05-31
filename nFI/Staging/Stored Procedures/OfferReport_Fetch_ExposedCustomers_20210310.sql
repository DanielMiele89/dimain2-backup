﻿
/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch nFI Exposed

Author		Hayden Reid
Created	23/09/2016
Purpose	Gets the Exposed Customers from nFI Offers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017  Hayden Reid
    - Added PubID > 0 clause to account for AMEX offers

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed PublisherID to [isWarehouse] column and logic
******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ExposedCustomers_20210310] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DISTINCT
	   o.IronOfferCyclesID
	   , FanID
	   , o.isWarehouse -- 2.0
	   , 1 Exposed
    FROM Warehouse.Staging.OfferReport_AllOffers o
    JOIN nFI.Relational.CampaignHistory h 
	   on h.IronOfferCyclesID = o.IronOfferCyclesID	   
    WHERE isWarehouse = 0 -- 2.0

END

GO
GRANT EXECUTE
    ON OBJECT::[Staging].[OfferReport_Fetch_ExposedCustomers_20210310] TO [jason]
    AS [dbo];


GO
GRANT VIEW DEFINITION
    ON OBJECT::[Staging].[OfferReport_Fetch_ExposedCustomers_20210310] TO [jason]
    AS [dbo];

