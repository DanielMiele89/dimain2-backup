

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/09/2015
-- Description: DD Report 
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0103_DirectDebit_Exceptions_Calc]
									
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0103_DirectDebit_Exceptions_Calc',
	TableSchemaName = 'Staging',
	TableName = 'R0103_DirectDebitExceptions',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



DECLARE @StartDate DATE,
	@EndDate DATE

SET @StartDate = DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE)))
SET @EndDate = DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))

IF OBJECT_ID ('tempdb..#HighTrans') IS NOT NULL DROP TABLE #HighTrans
SELECT	c.FanID,
	ClubID,
	SourceUID,
	COUNT(1) as TranCount
INTO #HighTrans
FROM Warehouse.relational.AdditionalCashbackAward aa
INNER JOIN Warehouse.Relational.Customer c
	ON aa.FanID = c.FanID
WHERE	aa.DirectDebitOriginatorID IS NOT NULL
	AND TranDate BETWEEN @StartDate AND @EndDate
GROUP BY c.FanID, ClubID, SourceUID
HAVING COUNT(1) > 25
ORDER BY COUNT(1) DESC

CREATE CLUSTERED INDEX IDX_FID ON #HighTrans (FanID)



IF OBJECT_ID ('Warehouse.Staging.R0103_DirectDebitExceptions') IS NOT NULL DROP TABLE Warehouse.Staging.R0103_DirectDebitExceptions
SELECT	c.ClubID,
	c.SourceUID as CIN,
	c.FanID,
	ddt.[Date] as TransactionDate,
	OIN,
	Narrative,
	Amount as TransactionAmount
INTO Warehouse.Staging.R0103_DirectDebitExceptions
FROM Archive_Light.dbo.[CBP_DirectDebit_TransactionHistory] ddt with (nolock)
INNER JOIN #HighTrans c
	ON ddt.FanID = c.FanID
LEFT OUTER JOIN SLC_Report.dbo.Trans t 
	ON t.VectorMajorID = ddt.FileID 
	AND t.VectorMinorID = ddt.RowNum 
	AND t.VectorID = 40
	AND t.TypeID = 23
	AND t.ItemID = 64
WHERE	ddt.[Date] BETWEEN DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(GETDATE()))+1,CAST(GETDATE() AS DATE)))
	AND DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE))
ORDER BY ddt.[Date]




/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0103_DirectDebit_Exceptions_Calc' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'R0103_DirectDebitExceptions' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Warehouse.Staging.R0103_DirectDebitExceptions)
WHERE	StoredProcedureName = 'SSRS_R0103_DirectDebit_Exceptions_Calc'
	AND TableSchemaName = 'Staging'
	AND TableName = 'R0103_DirectDebitExceptions' 
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

