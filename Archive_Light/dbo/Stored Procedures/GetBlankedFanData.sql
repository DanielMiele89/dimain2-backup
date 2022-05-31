/*
Allow Gas user, owner of linked server DIMAIN on DB7, to run this:
GRANT EXECUTE ON dbo.GetBlankedFanData TO Gas
*/
CREATE PROCEDURE [dbo].[GetBlankedFanData] 

	@FanID INT --= 9826586

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

--IF OBJECT_ID('tempdb..@FanTableChanges') IS NOT NULL DROP TABLE @FanTableChanges; 
DECLARE @FanTableChanges TABLE  (TableColumnsID INT, FanID INT, [Date] DATETIME, Value VARCHAR(MAX), ColumnName VARCHAR(200), Datatype VARCHAR(200), rn SMALLINT);
;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Nvarchar] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn) 
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5

;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Tinyint] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	CONVERT(varchar, [Value], 121) as [value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Datetime] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Int] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_varchar] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_bit] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Date] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = @FanID
)
INSERT INTO @FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 5

--  useful debugging date

DECLARE @SQLmiddle VARCHAR(4000) = '', @SQL VARCHAR(4000)

SELECT @SQLmiddle = @SQLmiddle + 
	', ' + ColumnName + ' = ' + CASE 
		WHEN Datatype = 'Nvarchar' THEN '''' + ISNULL([Value],'NULLX') + '''' 
		WHEN Datatype = 'Tinyint' THEN ISNULL([Value],'NULLX') 
		WHEN Datatype = 'Bit' THEN ISNULL([Value],'NULLX') 
		WHEN Datatype = 'Datetime' THEN '''' + ISNULL([Value],'NULLX') + ''''
		WHEN Datatype = 'Date' THEN '''' + ISNULL([Value],'NULLX') + ''''
		ELSE '???' END + CHAR(10)
FROM (
	SELECT *, 
		LastChange = MAX(CAST([Date] AS DATE)) OVER(PARTITION BY TableColumnsID)
	FROM @FanTableChanges fc
		CROSS APPLY (SELECT TOP(1) FanClearanceDate = MAX(CAST([Date] AS DATE)) FROM @FanTableChanges GROUP BY CAST([Date] AS DATE) ORDER BY COUNT(*) DESC) x
) d
WHERE LastChange = FanClearanceDate AND rn = 2

SET @SQL = 'UPDATE Fan SET ' + STUFF(@SQLmiddle,1,1,'') + ' WHERE FanID = ' + CAST(@FanID AS VARCHAR(20))
IF @SQL IS NOT NULL BEGIN
	PRINT @SQL
END
IF @SQL IS NULL BEGIN
	PRINT 'Sorry, procedure GetBlankedFanData was unable to resolve useful data. ' + CHAR(10) 
		+ 'Use the output to construct an update statement.'
	SELECT * FROM @FanTableChanges ORDER BY TableColumnsID, Date
END


RETURN 0


GO
GRANT EXECUTE
    ON OBJECT::[dbo].[GetBlankedFanData] TO [gas]
    AS [dbo];

