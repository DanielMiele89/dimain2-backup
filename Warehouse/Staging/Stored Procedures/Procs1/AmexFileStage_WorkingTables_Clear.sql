/******************************************************************************
Author: Jason Shipp
Created: 03/06/2019
Purpose: 
	- Clear Warehouse.Staging.AmexFileStage_FromPANlessTrans table so it can be refreshed

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.AmexFileStage_WorkingTables_Clear

AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE Warehouse.Staging.AmexFileStage_FromPANlessTrans;

END