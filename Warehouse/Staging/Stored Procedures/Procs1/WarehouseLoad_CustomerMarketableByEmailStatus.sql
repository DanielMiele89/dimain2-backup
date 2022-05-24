
-- *********************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2014
-- Description: Store a customers MarketableByEmail status on a daily basis where it has changed from the day previous
-- *********************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_CustomerMarketableByEmailStatus]
			
AS
BEGIN
	SET NOCOUNT ON;

DECLARE @RowCount INT
/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatus',
	TableSchemaName = 'Relational',
	TableName = 'Customer_MarketableByEmailStatus',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'

SET @RowCount = (SELECT COUNT(1) FROM Relational.Customer_MarketableByEmailStatus)


/******************************************************************************
*************************Marketable By Email Statuses**************************
******************************************************************************/
IF OBJECT_ID('tempdb..#MBE_Status') IS NOT NULL DROP TABLE #MBE_Status
SELECT	FanID,
	MarketableByEmail,
	CAST(GETDATE() AS DATE) as StartDate,
	CAST(NULL AS DATE) as EndDate
INTO #MBE_Status
FROM Relational.Customer


--**Index Temporary Table
CREATE CLUSTERED INDEX IDX_FanID ON #MBE_Status (FanID)
CREATE NONCLUSTERED INDEX IDX_MBE ON #MBE_Status (MarketableByEmail)
CREATE NONCLUSTERED INDEX IDX_SDate ON #MBE_Status (StartDate)


/***************************************************************
****************Delete Entries that already Exist***************
****************************************************************/
--**Delete any entries that are already in the 
--**Customer_MarketableByEmailStatus table
DELETE FROM #MBE_Status
FROM #MBE_Status mbe
INNER JOIN Relational.Customer_MarketableByEmailStatus c
	ON mbe.FanID = c.FanID
	AND mbe.MarketableByEmail = c.MarketableByEmail
WHERE c.EndDate IS NULL

/***************************************************************
******************Add EndDate to Old entries********************
****************************************************************/
--**For records where there are new entries, we must EndDate the
--**previous ones
UPDATE Relational.Customer_MarketableByEmailStatus
SET EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Relational.Customer_MarketableByEmailStatus mbes
INNER JOIN #MBE_Status mbe
	ON mbes.FanID = mbe.FanID
WHERE mbes.EndDate is null


/******************************************************************************
*****************************Insert new entries********************************
******************************************************************************/
--**Disable current Indexes on Table
--ALTER INDEX IDX_FanID ON Relational.Customer_MarketableByEmailStatus DISABLE
--ALTER INDEX IDX_StartDate ON Relational.Customer_MarketableByEmailStatus DISABLE
--ALTER INDEX IDX_EndDate ON Relational.Customer_MarketableByEmailStatus DISABLE

--**Run the insert of the new records
INSERT INTO Relational.Customer_MarketableByEmailStatus
SELECT	FanID,
	MarketableByEmail,
	StartDate,
	EndDate
FROM #MBE_Status

----**Rebuild Indexes on tables
--ALTER INDEX IDX_FanID ON Relational.Customer_MarketableByEmailStatus REBUILD
--ALTER INDEX IDX_StartDate ON Relational.Customer_MarketableByEmailStatus REBUILD
--ALTER INDEX IDX_EndDate ON Relational.Customer_MarketableByEmailStatus REBUILD



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatus' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_MarketableByEmailStatus' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(*) FROM Warehouse.Relational.Customer_MarketableByEmailStatus)-@RowCount
WHERE	StoredProcedureName = 'WarehouseLoad_CustomerMarketableByEmailStatus'
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_MarketableByEmailStatus' 
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END