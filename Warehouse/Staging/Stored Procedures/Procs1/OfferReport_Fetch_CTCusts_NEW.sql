/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the transactions for Warehouse Mailed, Control and nfi Control customers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CTCusts_NEW] 
	
AS
BEGIN
		
	SET NOCOUNT ON;

    SELECT DISTINCT
	    a.IronOfferID, c.CINID, c.Exposed FROM Staging.OfferReport_AllOffers a
    JOIN Staging.OfferReport_CTCustomersCINID c
	   ON (c.GroupID = a.ControlGroupID AND Exposed = 0 and c.PublisherID = a.PublisherID)
	   OR (c.GroupID = a.IronOfferCyclesID AND Exposed = 1 AND c.PublisherID = a.PublisherID)

END


