

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 27/07/2015
-- Description: Once vocafile data has been imported into SQL we need to transform it
--		and identify records we have not seen previously.
--		Fields in import data must be called RawData
-- ***************************************************************************

CREATE PROCEDURE [Staging].[Vocafile_ImportNewAdditionsForReview] (
			@TableNameA VARCHAR(200),
			@TableNameB VARCHAR(200),
			@DropSourceTables BIT
			)
	WITH EXECUTE AS OWNER								
AS
BEGIN
	SET NOCOUNT ON;

/***********************************************************************
***************************Import Table A*******************************
***********************************************************************/
DECLARE @Qry NVARCHAR(MAX),    
	@time DATETIME,
        @msg VARCHAR(2048)

SELECT @msg = 'Importing Table 1 - '+@TableNameA
EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

SET @Qry = '
IF OBJECT_ID (''tempdb..##RawData_Split'') IS NOT NULL DROP TABLE ##RawData_Split
SELECT	CAST(LEFT(RawData,1) as Char) as RecordType,
	RIGHT(LEFT(RawData,7),6) as Amendmentdate,
	CAST(RIGHT(LEFT(RawData,13),6) as int) as ServiceUserNumber,
	CAST(RIGHT(LEFT(RawData,46),33) as varchar(33)) as ServiceUserName,
	CAST(RIGHT(LEFT(RawData,79),33) as varchar(33)) as AddresseeName,
	CAST(RIGHT(LEFT(RawData,112),33) as varchar(33)) as PostalName,
	CAST(RIGHT(LEFT(RawData,145),33) as varchar(33)) as Address1
INTO ##RawData_Split
FROM '+@TableNameA

EXEC SP_ExecuteSQL @Qry

/***********************************************************************
***************************Import Table B*******************************
***********************************************************************/
IF @TableNameB <> '' 
BEGIN 
	SELECT @msg = 'Importing Table 2 - '+@TableNameB
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
	-----------------------------------------------------------------
	SET @Qry = '
	INSERT INTO ##RawData_Split
	SELECT	CAST(LEFT(RawData,1) as Char) as RecordType,
		RIGHT(LEFT(RawData,7),6) as Amendmentdate,
		CAST(RIGHT(LEFT(RawData,13),6) as int) as ServiceUserNumber,
		CAST(RIGHT(LEFT(RawData,46),33) as varchar(33)) as ServiceUserName,
		CAST(RIGHT(LEFT(RawData,79),33) as varchar(33)) as AddresseeName,
		CAST(RIGHT(LEFT(RawData,112),33) as varchar(33)) as PostalName,
		CAST(RIGHT(LEFT(RawData,145),33) as varchar(33)) as Address1
	FROM '+@TableNameB

	EXEC SP_ExecuteSQL @Qry
END

/*********************************************************************************
*****************Convert text AmendmentDate field to date type********************
*********************************************************************************/
SELECT	@msg = 'Creating - #Rawdata_Split_Format'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

IF OBJECT_ID('tempdb..#Rawdata_Split_Format') IS NOT NULL DROP TABLE #Rawdata_Split_Format
SELECT	DISTINCT
	RecordType,
	CAST(RIGHT(Amendmentdate, 2)+SUBSTRING(Amendmentdate, 3, 2)+LEFT(Amendmentdate, 2) AS DATE) as AmendmentDate,
	ServiceUserNumber,
	ServiceUserName,
	AddresseeName,
	PostalName,
	Address1
INTO #Rawdata_Split_Format
FROM ##Rawdata_Split


DROP TABLE ##Rawdata_Split


/*********************************************************************************
***************************Get the MAX Ammended Date******************************
*********************************************************************************/
SELECT	@msg = 'Creating - #Suns'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

IF OBJECT_ID ('tempdb..#Suns') IS NOT NULL DROP TABLE #Suns
SELECT	r.RecordType,
	r.ServiceUserName,
	r.ServiceUserNumber,
	AddresseeName,
	PostalName,
	Address1,
	MAX(r.AmendmentDate) as LastAmend
INTO #Suns
FROM #Rawdata_Split_Format r
GROUP BY r.RecordType, r.ServiceUserName, r.ServiceUserNumber, AddresseeName, PostalName, Address1



/*********************************************************************************
******************Truncate Old table and populate with New Data*******************
*********************************************************************************/
SELECT	@msg = 'Truncate and Re-populate - Warehouse.Relational.Vocafile_Latest'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------
TRUNCATE TABLE Warehouse.Relational.Vocafile_Latest

INSERT	INTO Warehouse.Relational.Vocafile_Latest
SELECT	RecordType,
	ServiceUserNumber as OIN,
	ServiceUserName as Narrative,
	AddresseeName,
	PostalName,
	Address1,
	LastAmend
FROM #Suns
WHERE RecordType = 'O'

SELECT	@msg = 'Rebuild Index on Warehouse.Relational.Vocafile_Latest'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------
ALTER INDEX ALL ON Warehouse.Relational.Vocafile_Latest REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212


/***********************************************************************************
******************Look for Suns missing from our data dictionary********************
***********************************************************************************/
SELECT	@msg = 'Inserting into #LatestAdditions'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

IF OBJECT_ID ('tempdb..#LatestAdditions') IS NOT NULL DROP TABLE #LatestAdditions
SELECT	r.*
INTO #LatestAdditions
FROM #Suns as r
LEFT OUTER JOIN Warehouse.Staging.DirectDebit_OINs as s
	ON r.ServiceUserNumber = s.OIN
	AND s.EndDate IS NULL
WHERE	RecordType = 'O' 
	AND s.OIN IS NULL
	AND s.EndDate IS NULL
ORDER BY ServiceUsername



/************************************************************************************************
***********Inserting New Additions into Warehouse.Staging.DirectDebit_OINs to be Assessed********
************************************************************************************************/
SELECT	@msg = 'Inserting New Additions into Warehouse.Staging.DirectDebit_OINs to be Assessed'
	EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
-----------------------------------------------------------------

INSERT INTO Warehouse.Staging.DirectDebit_OINs
SELECT	ServiceUserNumber as OIN,
	ServiceUserName as Narrative,
	1 as DirectDebit_StatusID,
	1 as DirectDebit_AssessmentReasonID,
	CAST(GETDATE() AS DATE) as AddedDate,
	1 as InternalCategoryID,
	1 as RBSCategoryID,
	NULL as StartDate,
	NULL as EndDate,
	NULL as DirectDebit_SupplierID
FROM #LatestAdditions


/************************************************************************************************
***********Inserting New Additions into Warehouse.Staging.DirectDebit_OINs to be Assessed********
************************************************************************************************/
IF @DropSourceTables = 1

	BEGIN

	SELECT	@msg = 'Drop Source File Raw DataTables'
		EXEC Warehouse.Staging.oo_TimerMessage @msg, @time OUTPUT
	-----------------------------------------------------------------
	SET @Qry =

	'
	DROP TABLE '+@TableNameA

	EXEC SP_EXECUTESQL @Qry

	IF @TableNameB <> ''

	BEGIN
		SET @Qry =

		'
		DROP TABLE '+@TableNameB

		EXEC SP_EXECUTESQL @Qry
	END

END


END