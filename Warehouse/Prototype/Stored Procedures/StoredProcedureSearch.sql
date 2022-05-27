
CREATE PROCEDURE [Prototype].[StoredProcedureSearch] @SearchString VARCHAR(MAX)
WITH EXECUTE AS OWNER
AS
BEGIN

	IF OBJECT_ID('tempdb..#Databases') IS NOT NULL DROP TABLE #Databases
	SELECT db.name AS DatabaseName
		 , database_id
	INTO #Databases
	FROM sys.databases db
	WHERE database_id NOT IN (1, 2, 3, 4, 5, 7, 10, 15, 18)

	IF OBJECT_ID('tempdb..#StoredProcSearchResults') IS NOT NULL DROP TABLE #StoredProcSearchResults
	CREATE TABLE #StoredProcSearchResults (DatabaseName VARCHAR(100)
										 , SchemaName VARCHAR(100)
										 , ObjectName VARCHAR(100)
										 , ObjectType VARCHAR(100))

	DECLARE @DatabaseID INT = (SELECT MIN(database_id) FROM #Databases)
		  , @MaxDatabaseID INT = (SELECT MAX(database_id) FROM #Databases)
		  , @DatabaseName VARCHAR(100)
		  , @Query VARCHAR(MAX)

	WHILE @DatabaseID <= @MaxDatabaseID
		BEGIN

			SELECT @DatabaseName = DatabaseName
			FROM #Databases
			WHERE database_id = @DatabaseID

			SET @Query = 
			'INSERT INTO #StoredProcSearchResults
			SELECT DISTINCT
				   ''' + @DatabaseName + ''' AS DatabaseName
				 , s.name AS SchemaName
     			 , o.name AS ObjectName
     			 , o.type_desc AS ObjectType
			FROM ' + @DatabaseName + '.sys.sql_modules m
			INNER JOIN ' + @DatabaseName + '.sys.objects o
				ON m.object_id = o.object_id
			INNER JOIN ' + @DatabaseName + '.sys.schemas s
				ON s.schema_id = o.schema_id
			WHERE m.definition LIKE ''' + @SearchString + ''''

			EXEC (@Query)

			SET @DatabaseID = (SELECT MIN(database_id) FROM #Databases WHERE database_id > @DatabaseID)

		END

	SELECT *
	FROM #StoredProcSearchResults

END