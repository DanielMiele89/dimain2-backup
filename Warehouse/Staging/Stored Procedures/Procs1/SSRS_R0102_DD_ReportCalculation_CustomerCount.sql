

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 16/09/2015
-- Description: DD Report Calculation
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0102_DD_ReportCalculation_CustomerCount]
									
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation_CustomerCount',
	TableSchemaName = 'Staging',
	TableName = 'R_0102_DD_DataTable_Customers',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



IF OBJECT_ID ('tempdb..#CustomerData') IS NOT NULL DROP TABLE #CustomerData
SELECT	*
INTO #CustomerData
FROM	(
	SELECT	Warehouse.Staging.fnGetStartOfMonth([Date]) as StartOfMonth,
		COUNT(DISTINCT SourceUID) as Unique_Transacting_Customers,
		'All RBSG' as GroupType
	FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory
	WHERE [Date] >= '2015-08-01'
	GROUP BY Warehouse.Staging.fnGetStartOfMonth([Date])
UNION ALL
	SELECT	Warehouse.Staging.fnGetStartOfMonth([Date]) as StartOfMonth,
		COUNT(DISTINCT ac.SourceUID) as Unique_Transacting_Customers,
		'MyRewards Only' as GroupType
	FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory ac
	INNER JOIN Warehouse.Relational.Customer c
		ON ac.SourceUID = c.SourceUID
	WHERE [Date] >= '2015-08-01'
	GROUP BY Warehouse.Staging.fnGetStartOfMonth([Date])
	)a


IF OBJECT_ID ('Warehouse.Staging.R_0102_DD_DataTable_Customers') IS NOT NULL DROP TABLE Warehouse.Staging.R_0102_DD_DataTable_Customers
SELECT	*
INTO Warehouse.Staging.R_0102_DD_DataTable_Customers
FROM #CustomerData



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation_CustomerCount' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0102_DD_DataTable_Customers' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Warehouse.Staging.R_0102_DD_DataTable_Customers)
WHERE	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation_CustomerCount'
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0102_DD_DataTable_Customers' 
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

TRUNCATE TABLE staging.JobLog_Temp


END