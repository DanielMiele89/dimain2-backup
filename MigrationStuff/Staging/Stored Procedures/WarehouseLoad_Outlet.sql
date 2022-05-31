
-- *************************************************
-- Author: Suraj Chahal
-- Create date: 04/02/2016
-- Description: Reload Outlet Table for Relational 
-- *************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Outlet]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Outlet',
	TableSchemaName = 'Staging',
	TableName = 'Outlet',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Staging.Outlet


/**********************************************************
******************Populate Outlet table********************
**********************************************************/
INSERT INTO Staging.Outlet
SELECT	ro.ID,
	ro.MerchantID,
	ro.PartnerID,
	LTRIM(RTRIM(f.Address1)) as Address1,
	LTRIM(RTRIM(f.Address2)) as Address2,
	LTRIM(RTRIM(f.City)) as City,		
	LEFT(LTRIM(RTRIM(f.PostCode)),10) as Postcode,
	CAST(NULL AS VARCHAR(6)) as PostalSector,
	CAST(NULL AS VARCHAR(2)) as PostArea,
	CAST(NULL AS VARCHAR(30)) as Region
FROM SLC_Report.dbo.RetailOutlet ro (NOLOCK)
INNER JOIN Relational.Partner p
	ON ro.PartnerID = p.PartnerID
LEFT OUTER JOIN SLC_Report.dbo.Fan f (NOLOCK) 
	ON ro.FanID = f.ID
WHERE	P.PartnerID > 0


/**********************************************************
******************Transform Outlet Data********************
**********************************************************/
UPDATE	Staging.Outlet
SET	PostalSector =	
		CASE
			WHEN REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][0-9][0-9][A-Z][A-Z]' THEN
					LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),2)+' '+RIGHT(LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),3),1)
			WHEN REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][0-9][0-9][0-9][A-Z][A-Z]' OR
					REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][A-Z][0-9][0-9][A-Z][A-Z]' OR 
					REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][0-9][A-Z][0-9][A-Z][A-Z]' THEN 
					LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),3)+' '+RIGHT(LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),4),1)
			WHEN REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][A-Z][0-9][0-9][0-9][A-Z][A-Z]' OR
					REPLACE(REPLACE(PostCode,CHAR(160),''),' ','') LIKE '[A-Z][A-Z][0-9][A-Z][0-9][A-Z][A-Z]'THEN 
					LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),4)+' '+RIGHT(LEFT(REPLACE(REPLACE(PostCode,CHAR(160),''),' ',''),5),1)
			ELSE ''
		END,
	PostArea =		
		CASE 
			WHEN PostCode LIKE '[A-Z][0-9]%' THEN LEFT(PostCode,1) 
			ELSE LEFT(PostCode,2) 
		END


UPDATE	Staging.Outlet
SET Region = pa.Region
FROM Staging.Outlet o
INNER JOIN Warehouse.Relational.PostArea pa
	ON o.PostArea = pa.PostAreaCode


ALTER INDEX ALL ON Staging.Outlet REBUILD
/****************************************************************/



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Outlet' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Outlet' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.Outlet)
WHERE	StoredProcedureName = 'WarehouseLoad_Outlet' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Outlet' 
	AND TableRowCount IS NULL




/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Outlet',
	TableSchemaName = 'Relational',
	TableName = 'Outlet',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Relational.Outlet



/****************************
************Insert***********
****************************/
INSERT INTO Relational.Outlet
SELECT	*
FROM Staging.Outlet


ALTER INDEX ALL ON Relational.Outlet REBUILD

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Outlet' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Outlet' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.Outlet)
WHERE	StoredProcedureName = 'WarehouseLoad_Outlet' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Outlet' 
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

TRUNCATE TABLE Staging.JobLog_Temp


END
