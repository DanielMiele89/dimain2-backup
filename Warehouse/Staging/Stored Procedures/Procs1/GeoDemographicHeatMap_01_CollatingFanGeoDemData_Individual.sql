
-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 18/08/2015
-- Description: By Customer this query creates a table containing a customers nearest
--		store by partner and their Gender, Age Group and CAMEO Group if they
--		have one.
--
--		This is the initial part of calculating a customers Geo Dem Heat Map in
--		Campaign Selection Process
-- *******************************************************************************
CREATE PROCEDURE [Staging].[GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual]
				(@PartnerID_Indiv INT)
WITH EXECUTE AS OWNER
			
AS
BEGIN
	SET NOCOUNT ON;

/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FanPartner',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


DECLARE @Qry NVARCHAR(MAX),    
	@time DATETIME,
        @msg VARCHAR(2048)
-----------------------------------------------------------------
SELECT @msg = 'Finding Partner Brand'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/*****************************************************************
*********************Finding Live Partners************************
*****************************************************************/
IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
SELECT	ROW_NUMBER() OVER(ORDER BY PartnerID) as RowNo,
	PartnerID,
	BrandID,
	PartnerName,
	BrandName
INTO #Brands
FROM Relational.Partner 
WHERE	PartnerID = @PartnerID_Indiv
--(32 row(s) affected)
CREATE CLUSTERED INDEX IDX_BrandID ON #Brands (BrandID)


-----------------------------------------------------------------
SELECT @msg = 'Identify All Activated Customers'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/*****************************************************************
******************Identify All Activated Customers****************
*****************************************************************/
CREATE TABLE #ActivatedCustBase
	(
	ID INT IDENTITY(1,1) NOT NULL,
	FanID INT NOT NULL,
	PostalSector VARCHAR(6) NOT NULL,
	Gender CHAR(1),
	AgeGroup VARCHAR (100),
	CAMEO_CODE_GRP VARCHAR(200)
	)

DECLARE @MaxFan INT,
	@MinFan INT,
	@ChunkSize INT

SET @MinFan = (SELECT MIN(FanID) FROM Relational.Customer)
SET @MaxFan = (SELECT MAX(FanID) FROM Relational.Customer)
SET @ChunkSize = 500000

WHILE @MinFan <= @MaxFan
BEGIN

	INSERT INTO #ActivatedCustBase
	SELECT	TOP (@ChunkSize)
		c.FanID,
		c.PostalSector,
		c.Gender,
		CASE	
			WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
			WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
			WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
			WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
			WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
			WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
		END AS Age_Group,
		ISNULL((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
	FROM Relational.Customer c
	LEFT OUTER JOIN Relational.CAMEO cam
		ON c.PostCode = cam.Postcode
	LEFT OUTER JOIN Relational.CAMEO_CODE_GROUP camg
		ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
	WHERE	CurrentlyActive = 1 
		AND c.FanID BETWEEN @MinFan AND @MaxFan
	ORDER BY c.FanID

	SET @MinFan = (SELECT MAX(FanID) FROM #ActivatedCustBase)+1

END

CREATE NONCLUSTERED INDEX IDX_FanID ON #ActivatedCustBase (FanID)
CREATE NONCLUSTERED INDEX IDX_PS ON #ActivatedCustBase (PostalSector)


-----------------------------------------------------------------
SELECT @msg = 'Populating the Fan Partner table'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/***********************************************************************************************
*****Populating the Fan Partner table which contains a record for each Partner for Each Fan*****
***********************************************************************************************/
DELETE 
FROM Staging.WRF_654_FanPartner
FROM Staging.WRF_654_FanPartner fp
INNER JOIN #Brands b
	ON fp.PartnerID = b.PartnerID
--------------------------------------


DECLARE @PartnerID2 INT,
	@StartRow5 INT

SET @StartRow5 = 1
SET @PartnerID2 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow5)

WHILE @StartRow5 <= (SELECT MAX(RowNo) FROM #Brands)

BEGIN
		INSERT INTO Staging.WRF_654_FanPartner
		SELECT	acb.FanID,
			b.PartnerID
		FROM #ActivatedCustBase acb
		INNER JOIN #Brands b
			ON b.PartnerID = @PartnerID2
		ORDER BY acb.FanID

	SET @StartRow5 = @StartRow5+1
	SET @PartnerID2 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow5) 

END




/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartner' 
	AND EndDate IS NULL


/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.WRF_654_FanPartner)
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartner' 
	AND TableRowCount IS NULL



/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FanPartnerDriveTime',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


-----------------------------------------------------------------
SELECT @msg = 'Finding Postcodes for Brands'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/**********************************************
****************Postodes by Brand**************
**********************************************/
IF OBJECT_ID ('tempdb..#PostcodesByPartner') IS NOT NULL DROP TABLE #PostcodesByPartner
SELECT	DISTINCT
	o.PartnerID,
	o.PostalSector,
	b.BrandName
INTO #PostcodesByPartner
FROM Relational.Outlet o
INNER JOIN SLC_Report.dbo.RetailOutlet ro 
	ON O.OutletID = RO.ID
INNER JOIN #Brands b 
	ON o.PartnerID = b.PartnerID -- live partner 
WHERE	ro.SuppressFromSearch = 0 
	AND Region IS NOT NULL
--(7402 row(s) affected)
CREATE CLUSTERED INDEX IDX_Partner ON #PostCodesByPartner (PartnerID)


-----------------------------------------------------------------
SELECT @msg = 'Finding a customers nearest store by Partner'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/***********************************************************
*******Finding a customers nearest store by Partner*********
***********************************************************/
--Create Final Output Table
DELETE 
FROM Staging.WRF_654_FanPartnerDriveTime
FROM Staging.WRF_654_FanPartnerDriveTime dt
INNER JOIN #Brands b
	ON dt.PartnerID = b.PartnerID



DECLARE @PartnerID INT,
	@StartRow INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow)

	WHILE @StartRow <= (SELECT MAX(RowNo) FROM #Brands)

	BEGIN
		INSERT INTO Staging.WRF_654_FanPartnerDriveTime
		SELECT	acb.FanID,
			pc.PartnerID,
			MIN(DriveTimeMins) as Nearest_Store,
			CAST(NULL AS VARCHAR(50)) as DriveTimeBand
		FROM #ActivatedCustBase acb
		INNER JOIN Relational.DriveTimeMatrix b 
			ON acb.PostalSector = b.FromSector
		INNER JOIN #PostcodesByPartner pc 
			ON b.ToSector = pc.PostalSector 
		WHERE	pc.PartnerID = @PartnerID
		GROUP BY acb.FanID,pc.PartnerID
		ORDER BY acb.FanID

	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow) 

END


-----------------------------------------------------------------
SELECT @msg = 'Adding DriveTimeBand Field'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/***********************************************************
*****************Adding DriveTimeBand Field*****************
***********************************************************/
UPDATE dt
SET DriveTimeBand = '01. Within 25 mins'
FROM Staging.WRF_654_FanPartnerDriveTime dt
INNER JOIN #Brands b
	ON dt.PartnerID = b.PartnerID
WHERE Nearest_Store <= 25


UPDATE dt
SET DriveTimeBand = '02. More than 25 mins'
FROM Staging.WRF_654_FanPartnerDriveTime dt
INNER JOIN #Brands b
	ON dt.PartnerID = b.PartnerID
WHERE Nearest_Store > 25



/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartnerDriveTime' 
	AND EndDate IS NULL


/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.WRF_654_FanPartnerDriveTime)
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartnerDriveTime' 
	AND TableRowCount IS NULL



/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FinalReferenceTable',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

-----------------------------------------------------------------
SELECT @msg = 'Building the final Reference Table'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

/**********************************************************************************
*************************Building the final Reference Table************************
**********************************************************************************/
--**Disable Indexes for faster inserts
ALTER INDEX IDX_FanID ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_Gender ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_AgeGroup ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_CAM ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_DriveTimeBand ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE



DELETE 
FROM Staging.WRF_654_FinalReferenceTable
FROM Staging.WRF_654_FinalReferenceTable dt
INNER JOIN #Brands b
	ON dt.PartnerID = b.PartnerID
 

DECLARE @StartRow3 INT,
	@PartnerID3 INT

SET @StartRow3 = 1
SET @PartnerID3 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow3)

WHILE @StartRow3 <= (SELECT MAX(RowNo) FROM #Brands)

BEGIN 

INSERT INTO Staging.WRF_654_FinalReferenceTable
SELECT	acb.FanID,
	acb.Gender,
	acb.AgeGroup,
	acb.CAMEO_CODE_GRP,
	fp.PartnerID,
	fpdt.DriveTimeBand
FROM #ActivatedCustBase acb
INNER JOIN Staging.WRF_654_FanPartner fp
	ON acb.FanID = fp.FanID
LEFT OUTER JOIN Staging.WRF_654_FanPartnerDriveTime fpdt
	ON fpdt.FanID = fp.FanID
	AND fp.PartnerID = fpdt.PartnerID
WHERE	fp.PartnerID = @PartnerID3
ORDER BY acb.FanID

SET @StartRow3 = @StartRow3+1
SET @PartnerID3 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow3) 

END

-----------------------------------------------------------------
SELECT @msg = 'Updating DriveTimeBand for Unknowns'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

UPDATE ft
SET DriveTimeBand = '99. Unknown'
FROM Staging.WRF_654_FinalReferenceTable ft
INNER JOIN #Brands b
	ON ft.PartnerID = b.PartnerID
WHERE DriveTimeBand IS NULL


-----------------------------------------------------------------
SELECT @msg = 'Rebuilding Final Indexes'
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

ALTER INDEX IDX_FanID ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD
ALTER INDEX IDX_Gender ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD
ALTER INDEX IDX_AgeGroup ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD
ALTER INDEX IDX_CAM ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD
ALTER INDEX IDX_DriveTimeBand ON Warehouse.Staging.WRF_654_FinalReferenceTable REBUILD

/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FinalReferenceTable' 
	AND EndDate IS NULL


/**********************************************************************
*************Update entry in JobLog Table with Row Count***************
**********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.WRF_654_FinalReferenceTable)
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemData_Individual' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FinalReferenceTable' 
	AND TableRowCount IS NULL


-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
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

