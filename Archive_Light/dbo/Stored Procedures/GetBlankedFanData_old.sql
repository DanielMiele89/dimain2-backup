/*
Allow Gas user, owner of linked server DIMAIN on DB7, to run this:
GRANT EXECUTE ON dbo.GetBlankedFanData TO Gas
*/
CREATE PROCEDURE [dbo].[GetBlankedFanData_old] 

	@SourceUID VARCHAR(20)

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON

IF OBJECT_ID('tempdb..#FanTableChanges') IS NOT NULL DROP TABLE #FanTableChanges; 
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
		AND dch.FanID = 6424715
)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn INTO #FanTableChanges FROM RawData WHERE rn < 3

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
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


;WITH RawData AS (
SELECT 
	TableColumnsID,
	FanID,
	[Date],
	[Value],
	tc.ColumnName, tc.Datatype,
	rn = ROW_NUMBER() OVER (PARTITION BY dch.TableColumnsID ORDER BY [Date] DESC)
FROM [Archive_Light].[ChangeLog].[DataChangeHistory_Datetime] dch
INNER JOIN [Archive_Light].[ChangeLog].[TableColumns] tc 
	ON tc.ID = dch.TableColumnsID
	WHERE tc.TableName = 'Fan'
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


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
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


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
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


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
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


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
		AND dch.FanID = 6424715
)
INSERT INTO #FanTableChanges (TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn)
SELECT TableColumnsID, FanID, [Date], [Value], ColumnName, Datatype, rn FROM RawData WHERE rn < 3


DECLARE @SQLmiddle VARCHAR(4000) = ''

SELECT @SQLmiddle = @SQLmiddle + 
	', ' + ColumnName + ' = ' + CASE 
		WHEN Datatype = 'Nvarchar' THEN '''' + [Value] + '''' 
		WHEN Datatype = 'Tinyint' THEN [Value] 
		WHEN Datatype = 'Bit' THEN [Value] 
		WHEN Datatype = 'Datetime' THEN '''' + [Value] + ''''
		ELSE '???' END + CHAR(10)
FROM (
	SELECT *, 
		LastChange = MAX(CAST([Date] AS DATE)) OVER(PARTITION BY TableColumnsID)
	FROM #FanTableChanges fc
		CROSS APPLY (SELECT TOP(1) FanClearanceDate = CAST([Date] AS DATE) FROM #FanTableChanges GROUP BY CAST([Date] AS DATE) ORDER BY COUNT(*) DESC) x
) d
WHERE LastChange = FanClearanceDate AND rn = 2

SELECT 'UPDATE Fan SET ' + STUFF(@SQLmiddle,1,1,'') + ' WHERE SourceUID = ''1049703738''' 

RETURN 0

