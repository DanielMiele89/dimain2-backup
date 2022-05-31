/*
Author: Suraj Chahal
Date: 22 Septemer 2015
Purpose:	Incrementally load the IronOfferMember table in the Staging schema of the Warehouse database
		This version is for during the week to minimise processing time, we are not reloading anything 
		that has been loaded before (does not allow for change).
			
*/
CREATE PROCEDURE [Staging].[WarehouseLoad_IronOfferMember]

AS
BEGIN

/**********************************************************
***************Write entry to JobLog Table*****************
**********************************************************/
Insert into Staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMember',
		TableSchemaName = 'Relational',
		TableName = 'IronOfferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'



--Counts pre-population
DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM Relational.IronOfferMember WITH (NOLOCK))
--*************Select Getdate() as StartDate, 'Find Missing People - Start'*************--


/****************************************************************************
**********See which customers already have records in  IronOfferMmber********
****************************************************************************/
--Get a distinct list of all customers who already have some records in IronOfferMember
IF OBJECT_ID ('tempdb..#AlreadyPresent') IS NOT NULL DROP TABLE #AlreadyPresent
SELECT	DISTINCT
	FanID
INTO #AlreadyPresent
FROM Relational.IronOfferMember WITH (NOLOCK)
--Index temporary table due to size
CREATE CLUSTERED INDEX ixc_AP ON #AlreadyPresent(FanID)


/*******************************************************************
*********Find those people in the customer table not in IOM*********
*******************************************************************/
--Get a list of those customers that have no records in IronOfferMember
IF OBJECT_ID ('tempdb..#MissingCustomers') IS NOT NULL DROP TABLE #MissingCustomers
SELECT	c.CompositeID
INTO #MissingCustomers
FROM Relational.Customer c WITH (NOLOCK)
LEFT OUTER JOIN #AlreadyPresent as ap
	on c.FanID = ap.FanID
WHERE ap.FanID IS NULL

CREATE CLUSTERED INDEX ixc_MC ON #MissingCustomers(CompositeID)



/******************************************************************************
**********Find out datetime of last imported record in Warehouse IOM***********
******************************************************************************/
--Find the number of the last record in the table
DECLARE @LastRecord INT
SET @LastRecord = (
		SELECT ISNULL(MAX(iom.IronOfferMemberID),0)
		FROM Relational.IronOfferMember iom
		)

--*************Select Getdate() as StartDate, 'Find Last RecordID - End'*************--


/**********************************************************************
*************Find records for previously unknown people****************
**********************************************************************/
--Select Getdate() as StartDate, 'Insert Missing people data - Start'
INSERT INTO Relational.IronOfferMember
SELECT	iom.ID as IronOfferMemberID,
	iom.IronOfferID,
	c.FanID,
	iom.StartDate,
	iom.EndDate,
	iom.ImportDate
FROM SLC_Report.dbo.IronOfferMember iom WITH (NOLOCK)
INNER JOIN #MissingCustomers mc WITH (NOLOCK)
	ON iom.CompositeID = mc.CompositeID
	AND iom.id <= @LastRecord
INNER JOIN Relational.Customer c (NOLOCK)
	ON iom.CompositeID = c.CompositeID


/**************************************************************
**************Find records loaded since last date**************
**************************************************************/
ALTER INDEX IDX_IID ON Relational.IronOfferMember DISABLE

INSERT INTO Relational.IronOfferMember
SELECT	iom.ID as IronOfferMemberID,
	iom.IronOfferID,
	c.FanID,
	iom.StartDate,
	iom.EndDate,
	iom.ImportDate
FROM SLC_Report.dbo.IronOfferMember as iom with (nolock)
INNER JOIN Relational.Customer as c with (nolock)
	ON iom.CompositeID = c.CompositeID
LEFT OUTER JOIN Relational.IronOfferMember as i with (nolock)
	--ON iom.IronOfferID = i.IronOfferID
	--AND iom.CompositeID = i.CompositeID
	ON iom.ID = i.IronOfferMemberID
	AND (iom.StartDate = i.StartDate OR (iom.StartDate IS NULL AND i.StartDate IS NULL))
	AND (iom.EndDate = i.EndDate OR (iom.EndDate IS NULL AND i.EndDate IS NULL))
WHERE	iom.ID > @LastRecord
	AND i.IronOfferMemberID IS NULL

ALTER INDEX ALL ON Relational.IronOfferMember REBUILD
/****************************************************************************
***************Update entry in JobLog Table with End Date********************
****************************************************************************/
UPDATE  Staging.JobLog_Temp
SET	EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMember' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronOfferMember' 
	AND EndDate IS NULL

/***********************************************************************
**************Update entry in JobLog Table with Row Count***************
***********************************************************************/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(*) FROM Relational.IronOfferMember)-@RowCount
WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMember'
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronOfferMember'
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	[StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp


END
