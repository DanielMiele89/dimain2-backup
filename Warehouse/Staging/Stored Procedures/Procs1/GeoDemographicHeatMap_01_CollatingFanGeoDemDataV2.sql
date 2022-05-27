

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 13/11/2014
-- Description: By Customer this query creates a table containing a customers nearest
--		store by partner and their Gender, Age Group and CAMEO Group if they
--		have one.
--
--		This is the initial part of calculating a customers Geo Dem Heat Map in
--		Campaign Selection Process
-- *******************************************************************************
CREATE PROCEDURE [Staging].[GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2] 
	WITH EXECUTE AS OWNER		
AS
BEGIN
	SET NOCOUNT ON;

/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FanPartner',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

	
/*****************************************************************
*********************Finding Live Partners************************
*****************************************************************/
IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
SELECT	ROW_NUMBER() OVER(ORDER BY a.PartnerID) as RowNo,
	a.PartnerID,
	p.BrandID,
	p.PartnerName,
	p.BrandName
INTO #Brands
FROM Warehouse.Relational.Partner_CBPDates a
INNER JOIN Warehouse.Relational.Partner p
	on a.PartnerID = p.PartnerID
WHERE	GETDATE() <= COALESCE(DATEADD(MM,5,Scheme_EndDate),GETDATE())
--(32 row(s) affected)
CREATE CLUSTERED INDEX IDX_BrandID ON #Brands (BrandID)


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

SET @MinFan = (SELECT MIN(FanID) FROM Warehouse.Relational.Customer)
SET @MaxFan = (SELECT MAX(FanID) FROM Warehouse.Relational.Customer)
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
	FROM Warehouse.Relational.Customer c
	LEFT OUTER JOIN Warehouse.Relational.CAMEO cam
		ON c.PostCode = cam.Postcode
	LEFT OUTER JOIN Warehouse.Relational.CAMEO_CODE_GROUP camg
		ON cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
	WHERE	CurrentlyActive = 1 
		AND c.FanID BETWEEN @MinFan AND @MaxFan
	ORDER BY c.FanID

	SET @MinFan = (SELECT MAX(FanID) FROM #ActivatedCustBase)+1

END

CREATE NONCLUSTERED INDEX IDX_FanID ON #ActivatedCustBase (FanID)
CREATE NONCLUSTERED INDEX IDX_PS ON #ActivatedCustBase (PostalSector)


/***********************************************************************************************
*****Populating the Fan Partner table which contains a record for each Partner for Each Fan*****
***********************************************************************************************/
TRUNCATE TABLE Warehouse.Staging.WRF_654_FanPartner

ALTER INDEX IDX_FanID ON Warehouse.Staging.WRF_654_FanPartner DISABLE
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FanPartner DISABLE

DECLARE @PartnerID2 INT,
	@StartRow5 INT

SET @StartRow5 = 1
SET @PartnerID2 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow5)

WHILE @StartRow5 <= (SELECT MAX(RowNo) FROM #Brands)

BEGIN
		INSERT INTO Warehouse.Staging.WRF_654_FanPartner
		SELECT	acb.FanID,
			b.PartnerID
		FROM #ActivatedCustBase acb
		INNER JOIN #Brands b
			ON b.PartnerID = @PartnerID2
		ORDER BY acb.FanID

	SET @StartRow5 = @StartRow5+1
	SET @PartnerID2 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow5) 

END

ALTER INDEX IDX_FanID ON Warehouse.Staging.WRF_654_FanPartner REBUILD
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FanPartner REBUILD



/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
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
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartner' 
	AND TableRowCount IS NULL



/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FanPartnerDriveTime',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


/**********************************************
****************Postodes by Brand**************
**********************************************/
IF OBJECT_ID ('tempdb..#PostcodesByPartner') IS NOT NULL DROP TABLE #PostcodesByPartner
SELECT	DISTINCT
	o.PartnerID,
	o.PostalSector,
	b.BrandName
INTO #PostcodesByPartner
FROM Warehouse.Relational.Outlet o
INNER JOIN SLC_Report.dbo.RetailOutlet ro 
	ON O.OutletID = RO.ID
INNER JOIN #Brands b 
	ON o.PartnerID = b.PartnerID -- live partner 
WHERE	ro.SuppressFromSearch = 0 
	AND Region IS NOT NULL
--(7402 row(s) affected)
CREATE CLUSTERED INDEX IDX_Partner ON #PostCodesByPartner (PartnerID)

/***********************************************************
*******Finding a customers nearest store by Partner*********
***********************************************************/
--Create Final Output Table
TRUNCATE TABLE Warehouse.Staging.WRF_654_FanPartnerDriveTime

ALTER INDEX IDX_Fan ON Warehouse.Staging.WRF_654_FanPartnerDriveTime DISABLE
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FanPartnerDriveTime DISABLE

DECLARE @PartnerID INT,
	@StartRow INT

SET @StartRow = 1
SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow)

	WHILE @StartRow <= (SELECT MAX(RowNo) FROM #Brands)

	BEGIN
		INSERT INTO Warehouse.Staging.WRF_654_FanPartnerDriveTime
		SELECT	acb.FanID,
			pc.PartnerID,
			MIN(DriveTimeMins) as Nearest_Store,
			CAST(NULL AS VARCHAR(50)) as DriveTimeBand
		FROM #ActivatedCustBase acb
		INNER JOIN Warehouse.Relational.DriveTimeMatrix b 
			ON acb.PostalSector = b.FromSector
		INNER JOIN #PostcodesByPartner pc 
			ON b.ToSector = pc.PostalSector 
		WHERE	pc.PartnerID = @PartnerID
		GROUP BY acb.FanID,pc.PartnerID
		ORDER BY acb.FanID

	SET @StartRow = @StartRow+1
	SET @PartnerID = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow) 

END


/***********************************************************
*****************Adding DriveTimeBand Field*****************
***********************************************************/
UPDATE Warehouse.Staging.WRF_654_FanPartnerDriveTime
SET DriveTimeBand = '01. Within 25 mins'
WHERE Nearest_Store <= 25

UPDATE Warehouse.Staging.WRF_654_FanPartnerDriveTime
SET DriveTimeBand = '02. More than 25 mins'
WHERE Nearest_Store > 25


ALTER INDEX IDX_Fan ON Warehouse.Staging.WRF_654_FanPartnerDriveTime REBUILD
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FanPartnerDriveTime REBUILD


/**********************************************************************
**************Update entry in JobLog Table with End Date***************
**********************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
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
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
	AND TableSchemaName = 'Staging' 
	AND TableName = 'WRF_654_FanPartnerDriveTime' 
	AND TableRowCount IS NULL



/**********************************************************************
*********************Write entry to JobLog Table***********************
**********************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2',
	TableSchemaName = 'Staging',
	TableName = 'WRF_654_FinalReferenceTable',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'

/**********************************************************************************
*************************Building the final Reference Table************************
**********************************************************************************/
TRUNCATE TABLE Warehouse.Staging.WRF_654_FinalReferenceTable
 
--**Disable Indexes for faster inserts
ALTER INDEX IDX_FanID ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_Gender ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_AgeGroup ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_CAM ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_PartnerID ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE
ALTER INDEX IDX_DriveTimeBand ON Warehouse.Staging.WRF_654_FinalReferenceTable DISABLE

DECLARE @StartRow3 INT,
	@PartnerID3 INT

SET @StartRow3 = 1
SET @PartnerID3 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow3)

WHILE @StartRow3 <= (SELECT MAX(RowNo) FROM #Brands)

BEGIN 

INSERT INTO Warehouse.Staging.WRF_654_FinalReferenceTable
SELECT	acb.FanID,
	acb.Gender,
	acb.AgeGroup,
	acb.CAMEO_CODE_GRP,
	fp.PartnerID,
	fpdt.DriveTimeBand
FROM #ActivatedCustBase acb
INNER JOIN Warehouse.Staging.WRF_654_FanPartner fp
	ON acb.FanID = fp.FanID
LEFT OUTER JOIN Warehouse.Staging.WRF_654_FanPartnerDriveTime fpdt
	ON fpdt.FanID = fp.FanID
	AND fp.PartnerID = fpdt.PartnerID
WHERE	fp.PartnerID = @PartnerID3
ORDER BY acb.FanID

SET @StartRow3 = @StartRow3+1
SET @PartnerID3 = (SELECT PartnerID FROM #Brands WHERE RowNo = @StartRow3) 

END


UPDATE Warehouse.Staging.WRF_654_FinalReferenceTable
SET DriveTimeBand = '99. Unknown'
WHERE DriveTimeBand IS NULL


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
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
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
WHERE	StoredProcedureName = 'GeoDemographicHeatMap_01_CollatingFanGeoDemDataV2' 
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




/***********************************************************
*************************Checking***************************
***********************************************************/
/*
SELECT	frt.*,
	p.PartnerName,
	plt.Response_Rank2
FROM Warehouse.Staging.WRF_654_FinalReferenceTable  frt
INNER JOIN Warehouse.Relational.Partner p
	ON frt.PartnerID = p.PartnerID
INNER JOIN Sandbox.Lloyd.Profiling_Lookup_Table_New plt
	ON frt.AgeGroup = plt.Age_Group
	AND frt.CAMEO_CODE_GRP = plt.CAMEO_grp
	AND frt.DriveTimeBand = plt.DriveTimeBand
	AND frt.Gender = plt.Gender
	AND p.BrandID = plt.brandid
WHERE FanID = 14955827



SELECT	p.PartnerName,
	COUNT(1),
	COUNT(DISTINCT dt.FanID)
FROM Warehouse.Staging.WRF_654_FinalReferenceTable dt
INNER JOIN Warehouse.Relational.Partner p 
	ON dt.PartnerID = p.PartnerID
GROUP BY p.PartnerName



SELECT	COUNT(1),
	COUNT(DISTINCT FanID)
FROM Warehouse.Staging.WRF_654_FanPartnerDriveTime 

SELECT	COUNT(1),
	COUNT(DISTINCT FanID)
FROM Warehouse.Staging.WRF_654_FinalReferenceTable	




select *
FROM #Brands b
LEFT JOIN sandbox.lloyd.Profiling_Lookup_Table l
	ON b.BrandID = l.brandid
WHERE l.brandid IS NULL

select brandname, response_index
from sandbox.lloyd.Profiling_Lookup_Table 
where Gender = 'M' and Age_Group = '04. 40 to 49' and CAMEO_grp = '05-White Collar Neighbourhoods' and DriveTimeBand ='01. Within 25 mins'
order by
*/

END