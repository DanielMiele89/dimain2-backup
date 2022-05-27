/******************************************************************************
Author: Rory
Created: 30/06/2021
Purpose:
	- Clears the Staging.PublisherOfferTracker tables so it can be refreshed
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[PublisherOfferTracker_Clear]
	
AS
BEGIN
	
	SET NOCOUNT ON;
	
	TRUNCATE TABLE [Staging].[PublisherOfferTracker_Import]
	TRUNCATE TABLE [Staging].[PublisherOfferTracker_Transformed]

END