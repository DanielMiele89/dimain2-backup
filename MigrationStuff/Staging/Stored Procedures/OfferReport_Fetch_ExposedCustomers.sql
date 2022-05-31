
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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ExposedCustomers] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#OfferReport_AllOffers') IS NOT NULL DROP TABLE #OfferReport_AllOffers
	SELECT	IronOfferCyclesID
	INTO #OfferReport_AllOffers
	FROM [Warehouse].[Staging].[OfferReport_AllOffers] o
    WHERE isWarehouse = 0
    AND IsVirgin = 0
    AND IsVirginPCA = 0
    AND IsVisaBarclaycard = 0

	CREATE CLUSTERED INDEX CIX_ ON #OfferReport_AllOffers (IronOfferCyclesID)

    SELECT	DISTINCT
			IronOfferCyclesID = o.IronOfferCyclesID
		,	Exposed = 1
		,	FanID = h.FanID
		,	isWarehouse = 0
		,	IsVirgin = 0
		,	IsVirginPCA = 0
		,	IsVisaBarclaycard = 0
    FROM #OfferReport_AllOffers o
    INNER JOIN [nFI].[Relational].[campaignhistory] h 
	   ON h.IronOfferCyclesID = o.IronOfferCyclesID

END

