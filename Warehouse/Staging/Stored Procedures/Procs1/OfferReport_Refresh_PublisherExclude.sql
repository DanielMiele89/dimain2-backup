/******************************************************************************
PROCESS NAME: Offer Calculation - Refresh Publisher Exclusions

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Truncates and inserts club-retailer combinations that are not managed by Reward

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Updated logic to use new Partner Deals structures

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Refresh_PublisherExclude] 
	
AS
BEGIN
		
	   SET NOCOUNT ON;

    TRUNCATE TABLE Staging.OfferReport_PublisherExclude

    INSERT INTO Staging.OfferReport_PublisherExclude
    SELECT 
	   PartnerID
	   , ClubID
	   , StartDate
	   , ISNULL(EndDate, '2050-01-01') EndDate
    FROM Relational.nFI_Partner_Deals np
    JOIN Relational.nFIPartnerDeals_Relationship_V2 nr
	   ON nr.ID = np.ManagedBy
    WHERE nr.IsRetailer = 0

END



