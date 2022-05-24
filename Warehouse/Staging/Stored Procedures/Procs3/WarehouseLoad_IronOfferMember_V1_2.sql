/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Incrementally load the IronOfferMember table in the Relational schema of the Warehouse database
			This version is for during the week to minimise processing time, we are not reloading anything 
			that has been loaded before (does not allow for change).
			
		
Update:		SB - 2017-07-22 - Amendment made to make sure new records don't break costraint	
-- CJM 20161116 no easy tuning opportunity
*/
CREATE Procedure [Staging].[WarehouseLoad_IronOfferMember_V1_2]
as
SET NOCOUNT ON

DECLARE @Now DATETIME, @JobLog_Start DATETIME = GETDATE()

--------------------------------------------------------------------------------------------------
-- Write entry to JobLog Table
--------------------------------------------------------------------------------------------------

--Counts pre-population CHANGED
DECLARE	@RowCount BIGINT, @RowsInserted BIGINT = 0

-------------------------------------------------------------------------------------
-- Get a distinct list of all customers who already have some records in ironoffermember
-------------------------------------------------------------------------------------
SET @Now = GETDATE()
if object_id('tempdb..#AlreadyPresent') is not null drop table #AlreadyPresent
SELECT DISTINCT CompositeID
INTO #AlreadyPresent
FROM Relational.Ironoffermember with (nolock) -- ix_Stuff2 / IX_IronOfferMember_CompositeIDEndDateStartDate_InclIronOfferID


--Index temporary table due to size
SET @Now = GETDATE()
CREATE UNIQUE CLUSTERED INDEX ixc_AP on #AlreadyPresent(CompositeID)

-------------------------------------------------------------------------------------
-- Get a list of those customers that have no records in ironoffermember 
-------------------------------------------------------------------------------------
SET @Now = GETDATE()
if object_id('tempdb..#MissingCustomers') is not null drop table #MissingCustomers
SELECT c.CompositeID
INTO #MissingCustomers
FROM Relational.Customer c with (nolock) 
WHERE NOT EXISTS (SELECT 1 FROM #AlreadyPresent ap WHERE c.CompositeID = ap.CompositeID)



-------------------------------------------------------------------------------------
-- Find the DATE of the last record in the destination table
-------------------------------------------------------------------------------------
SET @Now = GETDATE()
DECLARE @LastDate DATETIME -- = '2017-01-16 15:50:33.213' -- @LastRecord as int, 
SET @LastDate = (
	SELECT MAX(ImportDate)
	FROM Relational.IronOfferMember) -- ix_Stuff1



-------------------------------------------------------------------------------------
-- Load records for previously unknown people CJM 20161116 very slow
-------------------------------------------------------------------------------------
SET @Now = GETDATE()

--DECLARE @LastDate DATETIME = '2017-01-16 15:50:33.213' -- @LastRecord as int, 

INSERT INTO Relational.IronOfferMember (IronOfferID, CompositeID, StartDate, EndDate, ImportDate)
SELECT	--iom.ID as IronOfferMemberID,
	iom.IronOfferID,
	iom.CompositeID,
	iom.StartDate,
	iom.EndDate,
	iom.ImportDate
FROM SLC_Report.dbo.IronOfferMember iom with (nolock) -- ix_Stuff2 / IX_IronOfferMember_CompositeIDEndDateStartDate_InclIronOfferID
INNER JOIN #MissingCustomers mc with (nolock)
	ON iom.CompositeID = mc.CompositeID 
WHERE iom.ImportDate <= @LastDate
-- (173996 row(s) affected) / 00:00:42

SET @RowCount = @@ROWCOUNT
SET @RowsInserted = @RowsInserted + @RowCount
--EXEC [dbo].[oo_TimerMessage] 'Load records for previously unknown people', @Now, @RowCount



-------------------------------------------------------------------------------------
-- Collect & load records new since last import
-------------------------------------------------------------------------------------
SET @Now = GETDATE()
IF OBJECT_ID('tempdb..#IronOfferMember') IS NOT NULL DROP TABLE #IronOfferMember
SELECT iom.IronOfferID, iom.CompositeID, iom.StartDate, iom.EndDate, iom.ImportDate
INTO #IronOfferMember
FROM SLC_Report.dbo.IronOfferMember iom --ix_Stuff1 
WHERE EXISTS (SELECT 1 FROM Relational.Customer c WHERE iom.CompositeID = c.CompositeID)
	AND iom.ImportDate > @LastDate
-- (2946834 row(s) affected) / 00:00:11

CREATE UNIQUE CLUSTERED INDEX ucx_Stuff ON #IronOfferMember (IronOfferID, CompositeID, StartDate)




DELETE iom 
FROM #IronOfferMember iom 
WHERE EXISTS (
SELECT 1 FROM Warehouse.relational.IronOfferMember i with (nolock)
	WHERE iom.IronOfferID = i.IronOfferID 
	AND iom.CompositeID = i.CompositeID 
	AND (iom.StartDate = i.startdate or (iom.Startdate is null and i.StartDate is null) )
	AND (iom.EndDate = i.EndDate or (iom.EndDate is null and i.EndDate is null) )
)


INSERT INTO Relational.IronOfferMember (IronOfferID, CompositeID, StartDate, EndDate, ImportDate)
SELECT 	iom.IronOfferID,
		iom.CompositeID,
		iom.StartDate,
		iom.EndDate,
		iom.ImportDate
FROM #IronOfferMember iom --with (nolock)
SET @RowCount = @@ROWCOUNT
SET @RowsInserted = @RowsInserted + @RowCount

-------------------------------------------------------------------------------------------------
-- Update entry in JobLog Table with Row Count and end datetime
-------------------------------------------------------------------------------------------------
SET @Now = GETDATE()
INSERT INTO staging.JobLog
SELECT 
	[StoredProcedureName] = 'Warehouseload_IronOfferMember_V1_1',
	[TableSchemaName] = 'Relational',
	[TableName] = 'IronOfferMember',
	[StartDate] = @JobLog_Start,
	[EndDate] = GETDATE(),
	[TableRowCount] = @RowsInserted,
	[AppendReload] = 'A'