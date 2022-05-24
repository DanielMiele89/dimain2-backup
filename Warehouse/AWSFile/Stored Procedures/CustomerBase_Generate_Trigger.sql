/******************************************************************************
Author: Jason Shipp
Created: 10/08/2018
Purpose:
	- Create new fixed base table for the most recent complete calendar month
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CustomerBase_Generate_Trigger
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Execute stored procedure to create new fixed base table for the most recent complete calendar month to replace the table archived above
	******************************************************************************/

	DECLARE @StartDate DATE = CAST(DATEADD(YEAR,-3,DATEADD(DAY,1,DATEADD(DAY,-DAY(GETDATE()),GETDATE()))) AS DATE);
	DECLARE @EndDate DATE = CAST(DATEADD(DAY,-DAY(GETDATE()),GETDATE()) AS DATE);

	EXEC Warehouse.Relational.CustomerBase_Generate 'SalesVisSuite_FixedBase', @StartDate, @EndDate;
		
END