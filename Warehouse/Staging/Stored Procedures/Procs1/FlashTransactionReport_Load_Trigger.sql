/******************************************************************************
Author: Jason Shipp
Created: 12/06/2018
Purpose: 
	- Trigger the WarehouseStaging.FlashTransactionReport_Load stored procedure for given retailers and periods
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.FlashTransactionReport_Load_Trigger
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Execute stored procedures
	******************************************************************************/

	EXEC Warehouse.Staging.FlashTransactionReport_Load 'Waitrose', NULL, '2019-01-03', NULL;
	EXEC Warehouse.Staging.FlashTransactionReport_Load 'Morrisons', '4263', '2018-10-11', NULL;
	EXEC Warehouse.Staging.FlashTransactionReport_Load 'Now%TV', '4730', '2019-02-28', NULL;
	
END