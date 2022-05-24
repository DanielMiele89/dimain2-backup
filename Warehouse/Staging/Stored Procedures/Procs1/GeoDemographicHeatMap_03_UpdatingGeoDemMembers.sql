

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 11/12/2014
-- Description: Updates Warehouse.Relational.GeoDemographicHeatMap_Members and 
--		EndDates any records which have changed and inserts any new records
-- *******************************************************************************
CREATE PROCEDURE [Staging].[GeoDemographicHeatMap_03_UpdatingGeoDemMembers] 
	WITH EXECUTE AS OWNER		
AS
BEGIN
	SET NOCOUNT ON;

/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers',
	TableSchemaName = 'Staging',
	TableName = 'GeoDemographicHeatMap_InitialMembers',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


TRUNCATE TABLE Warehouse.Staging.GeoDemographicHeatMap_InitialMembers

--ALTER INDEX IDX_FanID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers DISABLE
ALTER INDEX IDX_PID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers	DISABLE
ALTER INDEX IDX_RID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers	DISABLE
ALTER INDEX IDX_HID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers	DISABLE


DECLARE	@StartRow INT,
	@PartnerID INT

IF OBJECT_ID ('tempdb..#Partners') IS NOT NULL DROP TABLE #Partners
SELECT	ROW_NUMBER() OVER(ORDER BY PartnerID) as RowNo,
	PartnerID
INTO #Partners
FROM	(
	SELECT	DISTINCT
		PartnerID
	FROM Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table
	)a
	
SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM #Partners WHERE RowNo = @StartRow)

WHILE @StartRow <= (SELECT MAX(RowNo) FROM #Partners)

BEGIN

	INSERT INTO Warehouse.Staging.GeoDemographicHeatMap_InitialMembers
	SELECT	frt.FanID,
		frt.PartnerID,
		lk.ResponseIndexBand_ID,
		lk.HeatMapID
	FROM Warehouse.Relational.GeoDemographicHeatMap_LookUp_Table lk
	INNER JOIN Warehouse.Staging.WRF_654_FinalReferenceTable frt
		ON lk.PartnerID = frt.PartnerID
		AND lk.AgeGroup = frt.AgeGroup
		AND lk.CAMEO_CODE_GRP = frt.CAMEO_CODE_GRP
		AND lk.Gender = frt.Gender
		AND lk.DriveTimeBand = frt.DriveTimeBand
	WHERE	lk.PartnerID = @PartnerID

	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM #Partners WHERE RowNo = @StartRow) 

END

--ALTER INDEX IDX_FanID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers REBUILD
ALTER INDEX IDX_PID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers REBUILD
ALTER INDEX IDX_RID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers REBUILD
ALTER INDEX IDX_HID ON Warehouse.Staging.GeoDemographicHeatMap_InitialMembers REBUILD



/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'GeoDemographicHeatMap_InitialMembers' 
	AND EndDate IS NULL
	

/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.GeoDemographicHeatMap_InitialMembers)
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'GeoDemographicHeatMap_InitialMembers' 
	AND TableRowCount IS NULL



/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers',
	TableSchemaName = 'Relational',
	TableName = 'GeoDemographicHeatMap_Members',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are new entries, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.GeoDemographicHeatMap_Members
SET EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.GeoDemographicHeatMap_Members m
INNER JOIN Warehouse.Staging.GeoDemographicHeatMap_InitialMembers im
	ON m.FanID = im.FanID
	AND m.PartnerID = im.PartnerID
	AND (m.ResponseIndexBand_ID <> im.ResponseIndexBand_ID OR m.HeatMapID <> im.HeatMapID)
WHERE m.EndDate IS NULL


/*******************************************************************************
******************************Insert new entries********************************
*******************************************************************************/
--ALTER INDEX IDX_FanID ON Relational.GeoDemographicHeatMap_Members DISABLE
ALTER INDEX IDX_PartnerID ON Relational.GeoDemographicHeatMap_Members DISABLE
ALTER INDEX IDX_RIB ON Relational.GeoDemographicHeatMap_Members DISABLE
ALTER INDEX IDX_HID ON Relational.GeoDemographicHeatMap_Members DISABLE
ALTER INDEX IDX_EndDate ON Relational.GeoDemographicHeatMap_Members DISABLE


INSERT INTO Warehouse.Relational.GeoDemographicHeatMap_Members
SELECT	im.FanID,
	im.PartnerID,
	im.ResponseIndexBand_ID,
	im.HeatMapID,
	CAST(GETDATE() AS DATE) as StartDate,
	CAST(NULL as DATE) as EndDate
FROM Warehouse.Staging.GeoDemographicHeatMap_InitialMembers im
LEFT OUTER JOIN Warehouse.Relational.GeoDemographicHeatMap_Members m
	ON im.FanID = m.FanID
	AND im.PartnerID = m.PartnerID
	AND im.ResponseIndexBand_ID = m.ResponseIndexBand_ID
	AND im.HeatMapID = m.HeatMapID
	AND m.EndDate IS NULL
WHERE m.FanID IS NULL


ALTER INDEX ALL ON Relational.GeoDemographicHeatMap_Members REBUILD


TRUNCATE TABLE Warehouse.Staging.GeoDemographicHeatMap_InitialMembers
TRUNCATE TABLE Warehouse.Staging.WRF_654_FanPartner
TRUNCATE TABLE Warehouse.Staging.WRF_654_FanPartnerDriveTime

/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'GeoDemographicHeatMap_Members' 
	AND EndDate IS NULL

/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.GeoDemographicHeatMap_Members WHERE StartDate = CAST(GETDATE() AS DATE))
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_03_UpdatingGeoDemMembers' 
	AND TableSchemaName = 'Relational' 
	AND TableName = 'GeoDemographicHeatMap_Members' 
	AND TableRowCount IS NULL


INSERT INTO staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp

END