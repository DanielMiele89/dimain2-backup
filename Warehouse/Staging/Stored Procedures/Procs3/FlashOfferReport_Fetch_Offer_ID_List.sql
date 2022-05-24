/******************************************************************************
Author: Jason Shipp
Created: 24/05/2018
Purpose:
	- Fetches list of IronOfferIDs to be used as parameter vales in the Staging.FlashOfferReport_Load_ConsumerTrans_Metrics stored procedure
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_Fetch_Offer_ID_List
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Fetch list of distinct IronOfferIDs from Warehouse.Staging.FlashOfferReport_All_Offers 
	******************************************************************************/

	SELECT DISTINCT
		a.IronOfferID 
	FROM Warehouse.Staging.FlashOfferReport_All_Offers a
	WHERE NOT EXISTS (
		SELECT NULL FROM Warehouse.Staging.FlashOfferReport_Metrics m
		WHERE
			a.IronOfferID = m.IronOfferID
			AND a.StartDate = m.StartDate
			AND a.EndDate = m.EndDate
			AND a.PeriodType = m.PeriodType
	)
	ORDER BY a.IronOfferID;

END