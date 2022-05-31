
-- ************************************************************************************
-- Author: Suraj Chahal
-- Create date: 05/02/2016
-- Description: Relational.Customer_PaymentCard with new entries and end date old ones
-- ************************************************************************************
CREATE PROCEDURE [Staging].[WarehouseLoad_Customer_PaymentCard]
		
AS
BEGIN
	SET NOCOUNT ON;

/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard',
	TableSchemaName = 'Staging',
	TableName = 'Customer_PaymentCard',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'


IF OBJECT_ID ('tempdb..#CustBase') IS NOT NULL DROP TABLE #CustBase
SELECT	CompositeID,
	FanID,
	ClubID
INTO #CustBase
FROM  Relational.Customer
--(1388880 row(s) affected)
CREATE CLUSTERED INDEX IDX_CID ON #CustBase (CompositeID)
CREATE NONCLUSTERED INDEX IDX_FID ON #CustBase (FanID)
CREATE NONCLUSTERED INDEX IDX_CL ON #CustBase (ClubID)


IF OBJECT_ID ('tempdb..#Cust_PCI') IS NOT NULL DROP TABLE #Cust_PCI
SELECT	PanID,
	cb.FanID,
	ClubID,
	pc.PaymentCardID,
	pc.AdditionDate,
	pc.DuplicationDate,
	pc.RemovalDate,
	pc.PaymentCardTypeID
INTO #Cust_PCI
FROM #CustBase cb
INNER JOIN
	(
	SELECT	p.ID as PanID,
		CompositeID,
		p.PaymentCardID,
		p.AdditionDate,
		p.DuplicationDate,
		p.RemovalDate,
		pc.CardTypeID as PaymentCardTypeID
	FROM SLC_Report.dbo.Pan p
	INNER JOIN SLC_Report.dbo.PaymentCard pc
		ON p.PaymentCardID = pc.ID
	)pc
	ON cb.CompositeID = pc.CompositeID
--(2472938 row(s) affected)

CREATE CLUSTERED INDEX IDX_FID ON #Cust_PCI (FanID)
CREATE NONCLUSTERED INDEX IDX_CL ON #Cust_PCI (ClubID)
CREATE NONCLUSTERED INDEX IDX_PC ON #Cust_PCI (PaymentCardID)
CREATE NONCLUSTERED INDEX IDX_P ON #Cust_PCI (PanID)


TRUNCATE TABLE Staging.Customer_PaymentCard


INSERT INTO Staging.Customer_PaymentCard
SELECT	PanID,
	FanID,
	ClubID,
	PaymentCardID,
	PaymentCardTypeID,
	DuplicationDate,
	AdditionDate as StartDate,
	RemovalDate as EndDate
FROM #Cust_PCI
--(2473553 row(s) affected)

--ALTER INDEX ALL ON Staging.Customer_PaymentCard REBUILD


/***************************************************************
****************Delete Entries that already Exist***************
***************************************************************/
--**Delete any entries that are already in the Relational Table
DELETE FROM Staging.Customer_PaymentCard
FROM Staging.Customer_PaymentCard spc
INNER JOIN Relational.Customer_PaymentCard cpc
	ON spc.PanID = cpc.PanID
	AND spc.FanID = cpc.FanID
	AND spc.ClubID = cpc.ClubID
	AND spc.PaymentCardID = cpc.PaymentCardID
	AND spc.PaymentCardTypeID = cpc.PaymentCardTypeID
	AND spc.StartDate = cpc.StartDate
	AND ISNULL(spc.EndDate,0) = ISNULL(cpc.EndDate,0)



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Customer_PaymentCard' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Staging.Customer_PaymentCard)
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'Customer_PaymentCard' 
	AND TableRowCount IS NULL



/**********************************************************
****************Write entry to JobLog Table****************
**********************************************************/
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard',
	TableSchemaName = 'Relational',
	TableName = 'Customer_PaymentCard',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'


/***************************************************************
******************Add EndDate to Old entries********************
****************************************************************/
--**For records where there are new entries, we must EndDate the
--**previous ones

UPDATE  Relational.Customer_PaymentCard
SET EndDate = spc.EndDate
FROM  Relational.Customer_PaymentCard cpc
INNER JOIN Staging.Customer_PaymentCard spc
	ON spc.PanID = cpc.PanID
	AND spc.FanID = cpc.FanID
	AND spc.ClubID = cpc.ClubID
	AND spc.PaymentCardID = cpc.PaymentCardID
	AND spc.PaymentCardTypeID = cpc.PaymentCardTypeID
	AND spc.StartDate = cpc.StartDate
WHERE cpc.EndDate IS NULL
--(359 row(s) affected)


INSERT INTO Relational.Customer_PaymentCard
SELECT	PanID,
	FanID,
	ClubID,
	PaymentCardID,
	PaymentCardTypeID,
	StartDate,
	EndDate
FROM Staging.Customer_PaymentCard
WHERE	DeduplicationDate IS NULL
	AND EndDate IS NULL



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE Staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_PaymentCard' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Relational.Customer_PaymentCard)
WHERE	StoredProcedureName = 'WarehouseLoad_Customer_PaymentCard' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'Customer_PaymentCard' 
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
