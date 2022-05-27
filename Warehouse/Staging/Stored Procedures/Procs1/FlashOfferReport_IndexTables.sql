/******************************************************************************
Author: Jason Shipp
Created: 29/05/2018
Purpose: 
	- Add indexes to customer and transaction tables for faster querying 
	
------------------------------------------------------------------------------
Modification History

Jason Shipp 14/11/2018
	- Replaced index on Staging.FlashOfferReport_ConsumerTransaction with one suggested by Chris

******************************************************************************/
CREATE PROCEDURE Staging.FlashOfferReport_IndexTables
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Build indexes on Warehouse.Staging.FlashOfferReport_ExposedControlCustomers
	******************************************************************************/

	--CREATE UNIQUE CLUSTERED INDEX UCX_FlashOfferReport_ExposedControlCustomers
	--	ON Warehouse.Staging.FlashOfferReport_ExposedControlCustomers (GroupID ASC, IsWarehouse ASC, Fanid ASC, Exposed ASC, ControlGroupTypeID ASC) WITH(FILLFACTOR = 80);

	--CREATE INDEX NIX_FlashOfferReport_ExposedControlCustomers 
	--	ON Warehouse.Staging.FlashOfferReport_ExposedControlCustomers (isWarehouse ASC, Exposed ASC, ControlGroupTypeID ASC, GroupID ASC) INCLUDE (CINID) WITH(FILLFACTOR = 80);

	/******************************************************************************
	Build indexes on Warehouse.Staging.FlashOfferReport_ConsumerTransaction
	******************************************************************************/

	--CREATE NONCLUSTERED INDEX IX_FlashOfferReport_ConsumerTransaction_MainCover
	--	ON Warehouse.Staging.FlashOfferReport_ConsumerTransaction (
	--		CINID
	--		, TranDate
	--		, ConsumerCombinationID
	--		, PartnerID
	--	);

	CREATE INDEX IX_FlashOfferReport_ConsumerTransaction_MainCoverV2 
		ON Staging.FlashOfferReport_ConsumerTransaction (PartnerID, TranDate) INCLUDE (Amount, CINID); -- Suggested by Chris

	/******************************************************************************
	Build indexes on Warehouse.Staging.FlashOfferReport_MatchTrans
	******************************************************************************/

	CREATE NONCLUSTERED INDEX IX_FlashOfferReport_MatchTrans
		ON Warehouse.Staging.FlashOfferReport_MatchTrans (
			FanID
			, TranDate
			, PartnerID
	);

END