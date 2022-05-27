-- =============================================
-- Author:		Dorota
-- Create date:	15/06/2015
-- =============================================

CREATE PROCEDURE MI.CampaignResultsLTE_Calculate_Part4 (@DatabaseName NVARCHAR(MAX)='Sandbox') AS -- -- unhide this row to modify SP
--DECLARE @DatabaseName NVARCHAR(MAX); SET @DatabaseName='Sandbox'  -- unhide this row to run code once

----------------------------------------------------------------------------------------------------------------------------
----------  Campaign Measurment Standard Code ------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------

/* Drops all @DatabaseName.@SchemaName.CampM_ tables*/

BEGIN
SET NOCOUNT ON;

DECLARE @Error AS INT
DECLARE @SchemaName AS NVARCHAR(MAX)

-- Choose Right SchemaName to store CampM_ tables, it depends on what database was selected in SP parameters, default is Sandbox.User_Name
IF @DatabaseName='Warehouse' 
    BEGIN 
	   SET @SchemaName='InsightArchive'
	   SET @Error=0
    END

ELSE IF @DatabaseName='Sandbox'
    BEGIN 
	   SET @SchemaName=(SELECT USER_NAME())
	   IF (SELECT COUNT(*) FROM SANDBOX.INFORMATION_SCHEMA.SCHEMATA WHERE Schema_Name=@SchemaName)>0
	   	   SET @Error=0
	   ELSE
		  SET @Error=1
    END

ELSE	  
    BEGIN
	   SET @SchemaName=(SELECT USER_NAME()) 
	   SET @Error=1
    END

-- Execute SP only if Sanbox or Warehouse selected, otherwise print error msg    
IF @Error=0 
BEGIN

-------------------------------------------------------------------------------------------------------------------
--- 0. Drop Tables ------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID('tempdb..#tmpTablesToDelete') IS NOT NULL DROP TABLE #tmpTablesToDelete
CREATE TABLE #tmpTablesToDelete (RowNumber INT PRIMARY KEY,Query NVARCHAR(MAX))

EXEC('INSERT INTO #tmpTablesToDelete
SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT (0))) RowNumber,
''DROP TABLE '' + Table_Catalog + ''.'' + Table_Schema +''.'' + Table_Name Query
FROM '+ @DatabaseName + '.' +  'INFORMATION_SCHEMA.TABLES
WHERE Table_Name like ''CampMLTE\_%''  ESCAPE(''\'')
AND Table_Schema=''' + @SchemaName + '''' )

DECLARE @Counter INT
SELECT @Counter = MAX(RowNumber) FROM #tmpTablesToDelete 

WHILE(@Counter > 0) 

BEGIN
    DECLARE @Query NVARCHAR(MAX)
    SELECT @Query = Query FROM #tmpTablesToDelete  WHERE RowNumber = @Counter
    PRINT @Query
    EXEC sp_executesql @statement = @Query
    SET @Counter = @Counter - 1
END

IF OBJECT_ID('tempdb..#tmpTablesToDelete') IS NOT NULL DROP TABLE #tmpTablesToDelete

END

ELSE 
PRINT 'Wrong Database selected (' + @DatabaseName + '.' + @SchemaName + '),  choose Warehouse or Sandbox'

END
