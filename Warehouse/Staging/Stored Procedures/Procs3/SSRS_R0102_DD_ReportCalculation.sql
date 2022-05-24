

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/09/2015
-- Description: DD Report Calculation
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0102_DD_ReportCalculation]
									
AS
BEGIN
	SET NOCOUNT ON;


/******************************************************************************
***********************Write entry to JobLog Table*****************************
******************************************************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation',
	TableSchemaName = 'Staging',
	TableName = 'R_0102_DD_DataTable',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'R'



/******************************************************************
****************Select OINs for Specific Suppliers*****************
******************************************************************/
IF OBJECT_ID ('tempdb..#OINs') IS NOT NULL DROP TABLE #OINs
SELECT	ID as OINID,
	SupplierID,
	OIN
INTO #OINS
FROM Warehouse.Relational.DirectDebit_OINs
WHERE	Status_Description = 'Accepted by RBSG'
--(1687 row(s) affected)
CREATE CLUSTERED INDEX IDX_OIN ON #OINS (OIN)



/****************************************************
****************Find all DD File IDs*****************
****************************************************/	
IF OBJECT_ID ('tempdb..#Files') IS NOT NULL DROP TABLE #Files
SELECT	ROW_NUMBER() OVER(ORDER BY nf.ID ASC) AS RowNo,
	ID as FileID
INTO #Files
FROM SLC_Report.dbo.NobleFiles nf
WHERE	FileType = 'DDTRN'
--(60 row(s) affected)
CREATE CLUSTERED INDEX IDX_FID ON #Files (FileID)


/**********************************************************
************Select OINs for Specific Suppliers*************
**********************************************************/
DECLARE	@RowNo INT,
	@LastRow INT,
	@FileID INT

SET @RowNo = 1
SET @LastRow = (SELECT MAX(RowNo) FROM #Files)


IF OBJECT_ID ('tempdb..#DD_Data') IS NOT NULL DROP TABLE #DD_Data
CREATE TABLE #DD_Data	(
			FileID INT,
			RowNum INT,
			ClubID SMALLINT,
			Amount MONEY,
			OIN INT,
			SourceUID VARCHAR(20),
			TranDate DATE,
			SupplierID INT
			)

WHILE @RowNo <= @LastRow
BEGIN
	
	SET @FileID = (SELECT FileID FROM #Files WHERE @RowNo = RowNo)

	INSERT INTO #DD_Data
	SELECT	dd.FileID,
		dd.RowNum,
		dd.ClubID,
		dd.Amount,
		dd.OIN,
		dd.SourceUID,
		dd.Date as TranDate,
		o.SupplierID
	FROM Archive_Light.dbo.CBP_DirectDebit_TransactionHistory dd
	INNER JOIN #OINS as o
		ON dd.OIN = o.OIN
	WHERE FileID = @FileID

	SET @RowNo = @RowNo+1
END

CREATE CLUSTERED INDEX IDX_DT ON #DD_Data (TranDate)
CREATE NONCLUSTERED INDEX IDX_OIN ON #DD_Data (OIN)



/**********************************************************
***************CREATE Grouped Summary Table****************
**********************************************************/
IF OBJECT_ID ('tempdb..#Summary') IS NOT NULL DROP TABLE #Summary
SELECT	Warehouse.Staging.fnGetStartOfMonth(TranDate) as StartOfMonth,
	ddo.InternalCategory2,
	ddo.SupplierID,
	SUM(Amount) as TotalAmountSpent,
	COUNT(1) as Transactions,
	COUNT(DISTINCT SourceUID) as Customers
INTO #Summary
FROM #DD_Data dd
INNER JOIN Warehouse.Relational.DirectDebit_OINs ddo
	ON dd.OIN = ddo.OIN 
	AND ddo.EndDate IS NULL
GROUP BY Warehouse.Staging.fnGetStartOfMonth(TranDate), ddo.InternalCategory2, ddo.SupplierID



/**********************************************************
******************CREATE #FinalDataTable*******************
**********************************************************/
IF OBJECT_ID ('Warehouse.Staging.R_0102_DD_DataTable') IS NOT NULL DROP TABLE Warehouse.Staging.R_0102_DD_DataTable
SELECT	StartOfMonth,
	InternalCategory2 as InternalCategory,
	dd.SupplierID,
	SupplierName,
	TotalAmountSpent,
	Transactions,
	Customers
INTO Warehouse.Staging.R_0102_DD_DataTable
FROM #Summary s
INNER JOIN Warehouse.Relational.DD_DataDictionary_Suppliers dd
	ON s.SupplierID = dd.SupplierID
WHERE CAST(StartOfMonth AS DATE) >= '2015-08-01'
ORDER BY StartOfMonth, InternalCategory2, SupplierName



/******************************************************************************
****************Update entry in JobLog Table with End Date*********************
******************************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0102_DD_DataTable' 
	AND EndDate IS NULL

/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Warehouse.Staging.R_0102_DD_DataTable)
WHERE	StoredProcedureName = 'SSRS_R0102_DD_ReportCalculation'
	AND TableSchemaName = 'Staging'
	AND TableName = 'R_0102_DD_DataTable' 
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