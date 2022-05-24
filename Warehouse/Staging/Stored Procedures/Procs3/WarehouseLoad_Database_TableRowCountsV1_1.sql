/*
Author:		Suraj Chahal
Date:		21-11-2013
Purpose:	Update Warehouse.Staging.Database_TableRowCounts table with daily updates of table counts after the ETL is run

*/
CREATE PROCEDURE [Staging].[WarehouseLoad_Database_TableRowCountsV1_1]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
INSERT INTO staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Database_TableRowCountsV1_1',
		TableSchemaName = 'Staging',
		TableName = 'Database_TableRowCounts',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

/*------------------------------------------------------------------------*/
------------------------Find All Tables to be assessed----------------------
/*------------------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#AssessmentTables') IS NOT NULL DROP TABLE #AssessmentTables
SELECT	TableID, 
	DatabaseName,
	SchemaName,
	TableName,
	(DatabaseName+'.'+SchemaName+'.'+TableName) as FullTableName
INTO #AssessmentTables
FROM Staging.Database_TablesToBeAssessed 
WHERE ToBeAssessed = 1
--SELECT * FROM #AssessmentTables

------------------------------------------------------------------------
--------------------------Declare the Variables-------------------------
------------------------------------------------------------------------
DECLARE @StartRow INT
DECLARE	@FullTableName varchar(250)

DECLARE	@DatabaseName varchar(50),
	@SchemaName varchar(50),
	@TableName varchar (150)

DECLARE	@Qry NVARCHAR(MAX)
/*--------------------------------------------------------------------------------------------------*/
----------Begin Loop to Populate Warehouse.Staging.Database_TableRowCounts table with New Data-------
/*--------------------------------------------------------------------------------------------------*/
SET @StartRow = 1

WHILE EXISTS (SELECT 1 FROM #AssessmentTables WHERE TableID >= @StartRow)
BEGIN


SET @FullTableName = (SELECT DatabaseName+'.'+SchemaName+'.'+TableName
		 FROM Warehouse.Staging.Database_TablesToBeAssessed WHERE ToBeAssessed = 1 AND TableID = @StartRow)
		
SET @DatabaseName = (SELECT DatabaseName FROM #AssessmentTables WHERE TableID = @StartRow)
SET @SchemaName = (SELECT SchemaName FROM #AssessmentTables WHERE TableID = @StartRow)
SET @TableName = (SELECT TableName FROM #AssessmentTables WHERE TableID = @StartRow)


SET @Qry = 
'IF OBJECT_ID('+Char(39)+'tempdb..#FinalTable'+Char(39)+') IS NOT NULL DROP TABLE #FinalTable
SELECT	''' + @DataBaseName+''' as DatabaseName,
	'''+@SchemaName+''' as SchemaName,
	'''+@TableName+''' as TableName,
	COUNT(1) as [RowCount],
	CAST(GETDATE() as DATE) as [Date]
INTO #FinalTable
FROM '+@FullTableName +
'

INSERT INTO Staging.Database_TableRowCounts
SELECT	ft.* 
FROM #FinalTable ft
LEFT OUTER JOIN Staging.Database_TableRowCounts tc
	ON	ft.DatabaseName = tc.DatabaseName
	AND	ft.SchemaName = tc.SchemaName
	AND	ft.TableName = tc.TableName
	AND	ft.[Date] = tc.[Date]
WHERE tc.DatabaseName IS NULL

'
/*---------------------------------------*/
----------Execute SQL to do insert--------
/*---------------------------------------*/
EXEC sp_Executesql @Qry

SET @StartRow = @StartRow+1


END


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set	EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Database_TableRowCountsV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'Database_TableRowCounts' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set	TableRowCount = (Select COUNT(*) from Warehouse.Staging.Database_TableRowCounts)
where	StoredProcedureName = 'WarehouseLoad_Database_TableRowCountsV1_1' and
		TableSchemaName = 'Staging' and
		TableName = 'Database_TableRowCounts' and
		TableRowCount is null


Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp


END