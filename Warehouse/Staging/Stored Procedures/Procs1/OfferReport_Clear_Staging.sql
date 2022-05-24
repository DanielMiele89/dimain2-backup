/******************************************************************************
PROCESS NAME: Offer Calculation - Clear Staging Tables

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Empties staging tables

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

02/05/2017 Hayden Reid - 2.0 Upgrade
    - Added additional tables

******************************************************************************/
CREATE PROCEDURE [Staging].[OfferReport_Clear_Staging] 
	
AS
BEGIN
	
	   SET NOCOUNT ON;

    TRUNCATE TABLE Warehouse.Staging.OfferReport_AllOffers
    --TRUNCATE TABLE Warehouse.Staging.OfferReport_AllOffers_Distinct - 2.0 (removed after performance issues)
    TRUNCATE TABLE Warehouse.Staging.OfferReport_PublisherExclude
    TRUNCATE TABLE Warehouse.Staging.OfferReport_CTCustomers
    TRUNCATE TABLE Warehouse.Staging.OfferReport_ConsumerCombinations
    TRUNCATE TABLE Warehouse.Staging.OfferReport_ThresholdMetrics
	TRUNCATE TABLE nFI.Relational.AmexOffer

END