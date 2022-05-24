/******************************************************************************
Author	  Jason Shipp
Created	  08/02/2018
Purpose	 
	Truncate staging tables on Warehouse, that aren't truncated within stored procedures

Modification History
******************************************************************************/

CREATE PROCEDURE Staging.ALS_Campaign_Cycle_Members_Clear_Staging

AS
BEGIN

	SET NOCOUNT ON;

	-- Truncate tables

	TRUNCATE TABLE Staging.ALS_Trans_Results;		
	
END