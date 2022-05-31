
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 01/02/2016
-- Description: Reload Customer Table for nFI Clubs in Relational.Club table 
-- *******************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Customer]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Customer',
	TableSchemaName = 'Staging',
	TableName = 'Customer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Staging.Customer


/**********************************
****Create Temp Publisher Table****
**********************************/
IF OBJECT_ID ('tempdb..#Clubs') IS NOT NULL DROP TABLE #Clubs
SELECT	ROW_NUMBER() OVER(ORDER BY ClubID) as RowNo,
	*
INTO #Clubs
FROM Relational.Club

CREATE CLUSTERED INDEX IDX_CID ON #Clubs (ClubID)


/**************************************************************
*******Inserting entries into the Staging.Customer table*******
**************************************************************/
DECLARE @RowNo SMALLINT
SET @RowNo = 1

WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Clubs)

BEGIN

INSERT INTO Staging.Customer
SELECT	ID as FanID,
	CompositeID,
	SourceUID,
	f.ClubID,
	CAST(CASE
		WHEN Sex = 1 THEN 'M'
		WHEN Sex = 2 THEN 'F'
		ELSE 'U'
	END as CHAR(1)) as Gender,
	(CASE WHEN DOB <> '1900-01-01 00:00:00.000' THEN DOB ELSE NULL END) as DOB,
	ISNULL(LTRIM(RTRIM(UPPER(CAST(Postcode AS VARCHAR(10))))),'') as PostCode,
	NULL as PostalSector,
	NULL as PostAreaCode,
	NULL as Region,
	RegistrationDate,
	Status,
	NULL as AgeCurrent,
	ClubCashPending,
	ClubCashAvailable
FROM SLC_Report.dbo.Fan f
INNER JOIN #Clubs cl
	ON f.ClubID = cl.ClubID
	AND cl.RowNo = @RowNo
	
SET @RowNo = @RowNo+1

END



/************************************
******Updating specific fields*******
************************************/
UPDATE c
SET	AgeCurrent =	CAST(CASE	
					WHEN DOB > CAST(GETDATE() AS DATE) THEN 0
					WHEN MONTH(DOB)>MONTH(GETDATE()) THEN DATEDIFF(YYYY,DOB,GETDATE())-1 
					WHEN MONTH(DOB)<MONTH(GETDATE()) THEN DATEDIFF(YYYY,DOB,GETDATE()) 
					WHEN MONTH(DOB)=MONTH(GETDATE()) THEN 
						CASE 
							WHEN DAY(DOB)>DAY(GETDATE()) THEN DATEDIFF(YYYY,DOB,GETDATE())-1 
							ELSE DATEDIFF(YYYY,DOB,GETDATE()) 
						END 
			 END AS TINYINT),
	PostalSector = CASE
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
	PostAreaCode =	CAST(CASE 
				WHEN PostCode IS NULL THEN ''
				WHEN PostCode LIKE '[A-Z][0-9]%' THEN LEFT(PostCode,1) 
				ELSE LEFT(PostCode,2) 
			END AS VARCHAR(2)),
	Region = pa.Region
FROM Staging.Customer c
LEFT OUTER JOIN Warehouse.Relational.PostArea pa
	ON (CASE WHEN c.PostCode LIKE '[A-Z][0-9]%' THEN LEFT(PostCode,1) ELSE LEFT(c.PostCode,2) END) = pa.PostAreaCode


ALTER INDEX ALL ON Staging.Customer REBUILD

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Customer' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Customer' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.Customer)
WHERE	StoredProcedureName = 'WarehouseLoad_Customer' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Customer' 
	AND TableRowCount IS NULL



/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Customer',
	TableSchemaName = 'Relational',
	TableName = 'Customer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Relational.Customer



/*****************************************************************
*******Inserting entries into the Relational.Customer table*******
*****************************************************************/
DECLARE @RowNo2 SMALLINT
SET @RowNo2 = 1

WHILE @RowNo2 <= (SELECT MAX(RowNo) FROM #Clubs)

BEGIN

INSERT INTO Relational.Customer
SELECT	c.*
FROM Staging.Customer c
INNER JOIN #Clubs cl
	ON c.ClubID = cl.ClubID
	AND cl.RowNo = @RowNo2
	
SET @RowNo2 = @RowNo2+1

END


ALTER INDEX ALL ON Relational.Customer REBUILD
/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Customer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.Customer)
WHERE	StoredProcedureName = 'WarehouseLoad_Customer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer' 
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



