/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch Warehouse Exposed and Control

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the Exposed and Control Customers from RBS Offers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_BigO_Custs] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    -- Drop Indexes 

    DECLARE @Qry NVARCHAR(MAX)
    SELECT @qry = (
	   SELECT 'DROP INDEX ' + ix.Name + ' ON Staging.' + OBJECT_NAME(object_id) + '; '
	   FROM sys.indexes ix
	   WHERE object_id = OBJECT_ID('Staging.OfferReport_BigO_Custs')
	   FOR XML PATH ('')
    )

    EXEC sp_executesql @qry

    SELECT 
	   x.FanID
	   , cl.CINID
	   , x.Exposed
    FROM (

	   SELECT DISTINCT
		  FanID
		  , 0 as Exposed
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN Warehouse.Relational.ControlGroupMembers cm  WITH (nolock)
		  ON cm.controlgroupid = o.controlgroupid
	   WHERE PublisherID = 132

	   UNION ALL

	   SELECT DISTINCT 
		  FanID
		  , 0 as Exposed
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN nFI.Relational.controlgroupmembers cm WITH (nolock)
		  ON cm.controlgroupid = o.ControlGroupID
	   WHERE PublisherID <> 132
    
	   UNION ALL

	   SELECT DISTINCT
		  FanID
		  , 1 as Exposed
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN Warehouse.Relational.CampaignHistory h WITH (nolock)
		  on h.IronOfferCyclesID = o.IronOfferCyclesID	   
	   WHERE PublisherID = 132
    ) x
    JOIN SLC_Report..Fan f on f.ID = x.FanID
    LEFT JOIN Warehouse.Relational.CINList cl on cl.CIN = f.SourceUID

    CREATE CLUSTERED INDEX CIX_FanEx ON Staging.OfferReport_BigO_Custs (FanID, Exposed)

END

