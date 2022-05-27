/******************************************************************************
Author: Jason Shipp
Created: 16/10/2018
Purpose: 
	- Fetch Iron Offer codes
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[WeeklySummaryV2_FetchIronOfferCode]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		ID AS IronOfferID
		, CAST(
			CASE 
				WHEN Name IN ('competitor','exclusive','occasional','preferred','unknown') THEN UPPER(LEFT(Name,1)) 
				WHEN IsTriggerOffer = 1 THEN 'TR'
				WHEN IsTriggerOffer = 0 THEN 'TA'
				ELSE ''
				END 
			AS VARCHAR(2)
		) AS OfferCode
	FROM [SLC_Report].[dbo].[IronOffer]
	UNION
	SELECT
		IronOfferID
		, CAST(
			CASE 
				WHEN IronOfferName IN ('competitor','exclusive','occasional','preferred','unknown') THEN UPPER(LEFT(IronOfferName,1)) 
				WHEN IsTriggerOffer = 1 THEN 'TR'
				WHEN IsTriggerOffer = 0 THEN 'TA'
				WHEN IsTriggerOffer IS NULL THEN 'TA'
				ELSE ''
				END 
			AS VARCHAR(2)
		) AS OfferCode
	FROM [WH_Visa].[Derived].[IronOffer]

	/******************************************************************************
	-- Create table for storing results on APW
	
	CREATE TABLE Transform.WeeklySummaryV2_IronOfferCode (
		IronOfferID int NOT NULL
		, OfferCode varchar(2) NOT NULL
		, PRIMARY KEY CLUSTERED (IronOfferID ASC) 
	) 
	******************************************************************************/

END