/******************************************************************************
PROCESS NAME: Offer Reporting - Calculate Performance - Convert Customers to CINID


Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Converts the customers for ConsumerTransaction from FanID to CINID

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_BigO_CustomersConversion] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT
	   cl.CINID
	   , oc.BinaryOffers
	   , oc.Exposed
    FROM Staging.OfferReport_BigO_CustOffers oc
    JOIN SLC_Report..Fan f ON f.ID = oc.FanID
    JOIN Warehouse.Relational.CINList cl ON cl.CIN = f.SourceUID
      

END