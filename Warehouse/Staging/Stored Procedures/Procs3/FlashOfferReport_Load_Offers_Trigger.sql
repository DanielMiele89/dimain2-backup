/******************************************************************************
Author: Jason Shipp
Created: 12/06/2018
Purpose: 
	- Trigger the Warehouse.Staging.FlashOfferReport_Load_Offers stored procedure for given retailers and periods
	- The Warehouse.Staging.FlashOfferReport_All_Offers table and Warehouse.Staging.FlashOfferReport_ConsumerCombinations table are refreshed
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Load_Offers_Trigger
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Clear tables
	******************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_All_Offers;
	TRUNCATE TABLE Warehouse.Staging.FlashOfferReport_ConsumerCombinations;

	/******************************************************************************
	Execute stored procedures
	******************************************************************************/

	DECLARE @Today date = CAST(GETDATE() AS date)
	SET DATEFIRST 1

	DECLARE @WaitroseStartDate date = DATEADD(day, -((DATEPART(dw, @Today))+6), @Today); -- Start (Monday) of last week
	EXEC Warehouse.Staging.FlashOfferReport_Load_Offers 'Waitrose', NULL, @WaitroseStartDate, NULL; -- Run Waitrose ETL to load cardholders for RetailerBespoke_Morrisons_TransByWeek report 
	
	DECLARE @MorrisonsStartDate date = DATEADD(day, -((DATEPART(dw, @Today))+6), @Today); -- Start (Monday) of last week
	EXEC Warehouse.Staging.FlashOfferReport_Load_Offers 'Morrisons', '4263', @MorrisonsStartDate, NULL; -- Run Morrisons ETL to load cardholders for RetailerBespoke_Morrisons_TransByWeek report 

END