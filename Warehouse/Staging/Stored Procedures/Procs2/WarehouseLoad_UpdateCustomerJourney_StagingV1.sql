/*
Author:		Suraj Chahal
Date:		26-09-2013
Purpose:	Update customer Journey status in CustomerJourney Table on a daily basis
		from the data in SLC_Report

		20-02-2014 - updated to remove references to warehouse
*/
Create PROCEDURE [Staging].[WarehouseLoad_UpdateCustomerJourney_StagingV1]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_UpdateCustomerJourneyV1_1',
		TableSchemaName = 'Staging',
		TableName = 'CustomerJourney_SLC_Report',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'




/*------------------------------------------------------------------------*/
---------------------------Declare the variables---------------------------
/*------------------------------------------------------------------------*/
DECLARE @StartRow INT,
	@ChunkSize INT
SET @StartRow = 0
SET @ChunkSize = 50000


/*------------------------------------------------------------------------*/
---------------Truncate Customer Journey Table to be Repopulated-----------
/*------------------------------------------------------------------------*/
TRUNCATE TABLE [Staging].[CustomerJourney_SLC_Report]


/*------------------------------------------------------------------------*/
------------------------Find Custs From SLC CJ Table------------------------
/*------------------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#DistinctCusts') IS NOT NULL DROP TABLE #DistinctCusts
SELECT	ROW_NUMBER() OVER(ORDER BY FanID) AS Row, 
	FanID
INTO #DistinctCusts
FROM (
	SELECT	DISTINCT
		FanID
	FROM SLC_Report.dbo.CustomerJourney
	)a

/*------------------------------------------------------------------------*/
-------------------Create Temp Table to fill with Chunks-------------------
/*------------------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#Temp_CJ') IS NOT NULL DROP TABLE #Temp_CJ
CREATE TABLE #Temp_CJ (Row INT NOT NULL,FanID INT NOT NULL)


/*------------------------------------------------------------------------*/
----------Begin Loop to Populate CustomerJourney table with New Data-------
/*------------------------------------------------------------------------*/
WHILE EXISTS (SELECT 1 FROM #DistinctCusts WHERE Row >= @StartRow)
BEGIN
---------------------------------------------
INSERT INTO #Temp_CJ
SELECT	TOP (@ChunkSize) Row, 
	FanID 
FROM #DistinctCusts 
WHERE Row > @StartRow 
ORDER BY Row
---------------------------------------------
INSERT INTO [Staging].[CustomerJourney_SLC_Report]
SELECT	* 
FROM SLC_Report.dbo.CustomerJourney 
WHERE	FanID IN (SELECT FanID FROM #Temp_CJ)
---------------------------------------------
SET @StartRow = (SELECT MAX(Row) FROM #Temp_CJ)
TRUNCATE TABLE #Temp_CJ
----------------------------------------------------
END



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_UpdateCustomerJourneyV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'Staging.CustomerJourney_SLC_Report' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = ((Select COUNT(*) from Warehouse.Relational.CustomerJourney))
where	StoredProcedureName = 'WarehouseLoad_UpdateCustomerJourneyV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'CustomerJourney_SLC_Report' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END