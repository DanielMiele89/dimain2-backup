/******************************************************************************
Author: Jason Shipp
Created: 10/08/2018
Purpose:
	- Rename current InsightArchive.SalesVisSuite_FixedBase table so that it is archived
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CustomerBase_ArchiveCurrentFixedBase
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Rename current InsightArchive.SalesVisSuite_FixedBase table so that it is archived
	******************************************************************************/

	DECLARE @BaseTableRename VARCHAR(50) = (
		SELECT CONCAT(
			'SalesVisSuite_FixedBase'
			, FORMAT(
				(DATEADD(month, -2, GETDATE()))
				, 'MMMyy'
			)
		)
	);

	EXEC sp_rename 'Warehouse.InsightArchive.SalesVisSuite_FixedBase', @BaseTableRename;

END