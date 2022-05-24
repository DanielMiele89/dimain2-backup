
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/06/2015
-- Description: Upload MOT3 Week1 customers to table so they can be excluded from
--		selections
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_MOT3Week1_Load]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_MOT3Week1_Load',
	TableSchemaName = 'Staging',
	TableName = 'MOT3Week1_Exclusions',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


/*****************************************************************************************************/

ALTER INDEX IDX_Fan ON Warehouse.Staging.MOT3Week1_Exclusions DISABLE

/********************************************************************
**********Find customers who are currently in MOT3 Week 1************
********************************************************************/
IF OBJECT_ID ('tempdb..#MOT3CompIDs') IS NOT NULL DROP TABLE #MOT3CompIDs
SELECT cj.fanid 
INTO #MOT3CompIDs
FROM Warehouse.relational.CustomerJourneyV2 cj
INNER JOIN warehouse.staging.CustomerJourney_MOTWeekNos mot
	ON cj.FanID = mot.FanID
WHERE	cj.EndDate IS NULL 
	AND cj.CustomerJourneyStatus = 'MOT3'
	AND mot.MOT3_WeekNo = 1


/*******************************************************
*********************Final Insert***********************
*******************************************************/
INSERT INTO Warehouse.Staging.MOT3Week1_Exclusions
SELECT	DISTINCT 
	a.FanID,
	CAST(GETDATE() AS DATE) as AddedDate
FROM #MOT3CompIDs as a
--

ALTER INDEX ALL ON Warehouse.Staging.MOT3Week1_Exclusions REBUILD
/*****************************************************************************************************/


/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_MOT3Week1_Load' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'MOT3Week1_Exclusions' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = 
		(
		SELECT COUNT(1) 
		FROM Warehouse.Staging.MOT3Week1_Exclusions 
		WHERE AddedDate = (SELECT MAX(AddedDate) FROM Warehouse.Staging.MOT3Week1_Exclusions)
		)
WHERE	StoredProcedureName = 'WarehouseLoad_MOT3Week1_Load'
	AND TableSchemaName = 'Staging'
	AND TableName = 'MOT3Week1_Exclusions' 
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
