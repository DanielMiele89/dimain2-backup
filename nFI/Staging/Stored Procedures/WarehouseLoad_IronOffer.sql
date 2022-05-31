
-- ***************************************************************
-- Author: Suraj Chahal
-- Create date: 01/02/2016
-- Description: Reload IronOffer Table for all nFI IronOffers
-- ***************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_IronOffer]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_IronOffer',
	TableSchemaName = 'Staging',
	TableName = 'IronOffer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Staging.IronOffer



/**********************************
****Create Temp Publisher Table****
**********************************/
IF OBJECT_ID ('tempdb..#Clubs') IS NOT NULL DROP TABLE #Clubs
SELECT	ROW_NUMBER() OVER(ORDER BY ClubID) as RowNo,
	*
INTO #Clubs
FROM Relational.Club

CREATE CLUSTERED INDEX IDX_CID ON #Clubs (ClubID)



/*******************************
*************Insert*************
*******************************/
DECLARE @RowNo SMALLINT
SET @RowNo = 1

WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Clubs)

BEGIN

INSERT INTO Staging.IronOffer
SELECT	io.ID,
	NULL as OfferID,
	Name as IronOfferName,
	StartDate,
	EndDate,
	PartnerID,
	IsSignedOff,
	ioc.ClubID,
	IsAppliedToAllMembers
FROM SLC_Report.dbo.IronOffer io
INNER JOIN SLC_Report.dbo.IronOfferClub ioc
	ON io.ID = ioc.IronOfferID
INNER JOIN #Clubs cl
	ON ioc.ClubID = cl.ClubID
	AND cl.RowNo = @RowNo
	
SET @RowNo = @RowNo+1

END

ALTER INDEX ALL ON Staging.IronOffer REBUILD

/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'IronOffer' 
	AND EndDate IS NULL


/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.IronOffer)
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'IronOffer' 
	AND TableRowCount IS NULL




/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_IronOffer',
	TableSchemaName = 'Relational',
	TableName = 'IronOffer',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/***********************************
***********Truncate Table***********
***********************************/
TRUNCATE TABLE Relational.IronOffer



/*******************************
*************Insert*************
*******************************/
DECLARE @RowNo2 SMALLINT
SET @RowNo2 = 1

WHILE @RowNo2 <= (SELECT MAX(RowNo) FROM #Clubs)

BEGIN

INSERT INTO Relational.IronOffer
SELECT	i.*
FROM Staging.IronOffer i
INNER JOIN #Clubs cl
	ON i.ClubID = cl.ClubID
	AND cl.RowNo = @RowNo2

SET @RowNo2 = @RowNo2+1

END

ALTER INDEX ALL ON Relational.IronOffer REBUILD



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronOffer' 
	AND EndDate IS NULL


/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.IronOffer)
WHERE	StoredProcedureName = 'WarehouseLoad_IronOffer' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronOffer' 
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
