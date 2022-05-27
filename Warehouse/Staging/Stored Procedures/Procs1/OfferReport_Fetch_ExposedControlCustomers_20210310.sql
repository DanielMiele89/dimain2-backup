/******************************************************************************
PROCESS NAME: Offer Calculation - Fetch Warehouse Exposed and Control

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the Exposed and Control Customers from RBS Offers

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

03/01/2017  Hayden Reid
    - Added UNION for AMEX offers.  When AMEX becomes an official publisher, this union will need to be changed to account for it.

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Changed logic to get FanID's and CINID's at the same time
    - Added [isWarehouse] logic and added column to output

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Fetch_ExposedControlCustomers_20210310] 
	
AS
BEGIN
	
	   SET NOCOUNT ON;

    SELECT 
	   x.*
	   , cl.CINID
    FROM (
	   SELECT DISTINCT
		  o.ControlGroupID GroupID
		  , FanID
		  , 0 as Exposed
		  , o.isWarehouse
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN Warehouse.Relational.ControlGroupMembers cm 
		  ON cm.controlgroupid = o.controlgroupid
	   WHERE isWarehouse = 1

	   UNION ALL

	   SELECT DISTINCT 
		  o.ControlGroupID
		  , FanID
		  , 0 as Exposed
		  , o.isWarehouse
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN nFI.Relational.controlgroupmembers cm 
		  ON cm.controlgroupid = o.ControlGroupID
	   WHERE isWarehouse = 0
    
	   UNION ALL

	   SELECT DISTINCT
		  o.IronOfferCyclesID
		  , FanID
		  , 1 as Exposed
		  , o.isWarehouse
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN Warehouse.Relational.CampaignHistory h
		  on h.IronOfferCyclesID = o.IronOfferCyclesID	   
	   WHERE isWarehouse = 1

	   UNION ALL

	   /** AMEX Offers **/
	   SELECT DISTINCT
		  o.ControlGroupID
		  , FanID
		  , 0 as Exposed
		  , o.isWarehouse
	   FROM Warehouse.Staging.OfferReport_AllOffers o
	   JOIN nFI.Relational.AmexControlGroupMembers cm
		  ON cm.AmexControlgroupID = o.ControlGroupID
	   WHERE isWarehouse IS NULL
    ) x
    LEFT JOIN SLC_Report..Fan f ON f.ID = x.FanID
    LEFT JOIN Relational.CINList cl ON cl.CIN = f.SourceUID
	--WHERE NOT EXISTS ( -- Use this if the load into Staging.OfferReport_CTCustomers was paused and continuing will be quicker than restarting the whole calculation process
	--	SELECT NULL FROM Warehouse.Staging.OfferReport_CTCustomers ct
	--	WHERE 
	--	x.GroupID = ct.GroupID
	--	AND x.Exposed = ct.Exposed
	--	AND ((x.isWarehouse = ct.isWarehouse) OR (x.isWarehouse IS NULL AND ct.isWarehouse IS NULL))
	--	AND x.fanid = ct.FanID
	--);

END