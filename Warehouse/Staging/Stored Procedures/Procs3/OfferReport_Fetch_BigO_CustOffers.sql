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
CREATE PROCEDURE [Staging].[OfferReport_Fetch_BigO_CustOffers] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT
	   bc.FanID
	   , bc.CINID
	   , (
		  (
			 SELECT '' + ISNULL(CAST(x.AllOfferID/x.AllOfferID AS VARCHAR), 0)
			 FROM Warehouse.Staging.OfferReport_AllOffers t
			 LEFT JOIN (
				SELECT 
				    cm.FanID
				    , t.ID AllOfferID
				    , 0 Exposed
				FROM Warehouse.Staging.OfferReport_AllOffers t
				JOIN Warehouse.Relational.ControlGroupMembers cm
				    ON cm.controlgroupid = t.ControlGroupID
				WHERE PublisherID = 132

				UNION ALL

				SELECT 
				    cm.FanID
				    , t.ID AllOfferID
				    , 0 Exposed 
				FROM Warehouse.Staging.OfferReport_AllOffers t
				JOIN nfi.Relational.ControlGroupMembers cm
				    ON cm.controlgroupid = t.ControlGroupID
				WHERE PublisherID <> 132

				UNION ALL

				SELECT 
				    ch.FanID
				    , t.ID AllOfferID
				    , 1 Exposed 
				FROM Warehouse.Staging.OfferReport_AllOffers t
				JOIN Warehouse.Relational.CampaignHistory ch
				    ON ch.ironoffercyclesid = t.IronOfferCyclesID
				WHERE PublisherID = 132
			 ) x 
				ON x.AllOfferID = t.ID
				AND x.FanID = bc.FanID
			 ORDER BY t.ID
			 FOR XML PATH(''), TYPE
		  ).value('.', 'NVARCHAR(MAX)')
	   ) BinaryOffers
	   , Exposed
    FROM Warehouse.Staging.OfferReport_BigO_Custs bc
    
END