
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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ExposedCustomers_20220329] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT	DISTINCT
			o.IronOfferCyclesID
		,	FanID
		,	o.isWarehouse -- 2.0
		,	o.IsVirgin -- 2.0
		,	o.IsVisaBarclaycard -- 2.0
		,	1 Exposed
    FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
    INNER JOIN [nFI].[Relational].[campaignhistory] h 
	   ON h.IronOfferCyclesID = o.IronOfferCyclesID	   
    WHERE isWarehouse = 0 -- 2.0
    AND IsVirgin = 0 -- 2.0
    AND IsVisaBarclaycard = 0 -- 2.0

END

