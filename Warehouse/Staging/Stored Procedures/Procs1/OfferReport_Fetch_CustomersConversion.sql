/******************************************************************************
PROCESS NAME: Offer Reporting - Calculate Performance - Convert Customers to CINID
PID: OC-005

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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_CustomersConversion] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    -- DROP INDEXES
    DECLARE @Qry NVARCHAR(MAX)
    SELECT @qry = (
	   SELECT 'DROP INDEX ' + ix.Name + ' ON Staging.' + OBJECT_NAME(object_id) + '; '
	   FROM sys.indexes ix
	   WHERE object_id = OBJECT_ID('Staging.OfferReport_CTCustomersCINID')
	   FOR XML PATH ('')
    )

    EXEC sp_executesql @qry

    SELECT
	   oc.GroupID
	   , cl.CINID
	   , oc.Exposed
	   , oc.PublisherID
    FROM Staging.OfferReport_CTCustomers oc
    JOIN SLC_Report..Fan f ON f.ID = oc.FanID
    JOIN Warehouse.Relational.CINList cl ON cl.CIN = f.SourceUID
      
    CREATE CLUSTERED INDEX CIX_CinGroup ON Staging.OfferReport_CTCustomersCINID ([CINID] ASC, [GroupID] ASC, [Exposed] ASC, [PublisherID] ASC)
END


