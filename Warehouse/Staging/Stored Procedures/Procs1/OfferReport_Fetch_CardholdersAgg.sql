/******************************************************************************
PROCESS NAME: Offer Aggregation - Distinct Cardholder Count


Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the count of distinct cardholders for each partner
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added ControlGroupTypeID to ControlGroup counts

24/01/2019 Jason Shipp
	- Deleted commented out code

******************************************************************************/

CREATE PROCEDURE [Staging].[OfferReport_Fetch_CardholdersAgg]
(
    @isMonthly BIT
)
AS
BEGIN

	SET NOCOUNT ON

    SELECT *
    FROM Staging.OfferReport_CardholdersAgg
    
END