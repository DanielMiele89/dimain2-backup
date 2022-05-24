/******************************************************************************
Author: Jason Shipp
Created: 01/10/2019
Purpose:
	- Clears the APW.AmexExposedClickCounts table so it can be refreshed
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.AmexExposedClickCounts_Clear
	
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Warehouse.APW.AmexExposedClickCounts;

END