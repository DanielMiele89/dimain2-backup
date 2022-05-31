


CREATE PROC [ChangeLog].[PopulateChangesByTableColumnsID]
	@TableColumnsID int
as

set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare 
	@query varchar(2048),
	@Now datetime = getdate(),
	@TableName varchar(50),
	@ColumnName varchar(50),
	@Datatype varchar(20),
	@TargetTableName varchar(50)

select 
	@TableName = TableName,
	@ColumnName = ColumnName,
	@Datatype = Datatype 
from ChangeLog.TableColumns where ID = @TableColumnsID -- 35 rows, mostly Fan

if @ColumnName is null 
	begin
		print 'Column not available.'
		return
	end

select @TargetTableName = 
	case @Datatype
		when 'Nvarchar' then 'ChangeLog.DataChangeHistory_Nvarchar'
		when 'int' then 'ChangeLog.DataChangeHistory_Int'
		when 'Tinyint' then 'ChangeLog.DataChangeHistory_Tinyint'
		when 'Datetime' then 'ChangeLog.DataChangeHistory_Datetime'
		when 'Bit' then 'ChangeLog.DataChangeHistory_Bit'
		when 'smallmoney' then 'ChangeLog.DataChangeHistory_Smallmoney'
		when 'Date' then 'ChangeLog.DataChangeHistory_Date'
		else 'ChangeLog.DataChangeHistory_Varchar'
	end


-- prepare query based on the table
IF @TableName = 'Fan'
	SELECT @query = 
		'INSERT INTO ' + @TargetTableName + ' (TableColumnsID, FanID, [Date], [Value])
		SELECT ' + CONVERT(VARCHAR(10),@TableColumnsID) + ', f.ID, ''' + CONVERT(VARCHAR(50),@Now)  + ''', f.' + @ColumnName + '
		FROM SLC_Report.dbo.Fan f
		OUTER APPLY (
			SELECT TOP 1 [value] 
			FROM ' + @TargetTableName + ' 
			WHERE TableColumnsID = ' + CONVERT(VARCHAR(10),@TableColumnsID) + ' 
				AND FanID = f.ID
			ORDER BY [Date] DESC
		) x
		WHERE x.[value] <> f.' + @ColumnName + '
			OR (x.[value] IS NULL AND f.' + @ColumnName + ' IS NOT NULL)
			OR (x.[value] IS NOT NULL AND f.' + @ColumnName + ' IS NULL)'

ELSE IF @TableName = 'BankAccount'
	SELECT @query = 
		'INSERT INTO ' + @TargetTableName + ' (TableColumnsID, FanID, [Date], [Value])
		SELECT ' + convert(varchar(10),@TableColumnsID) + ', d.ID, ''' + convert(varchar(50),@Now)  + ''', d.' + @ColumnName + '
		FROM (
			SELECT d.ID, d.' + @ColumnName + '
			FROM SLC_Report.dbo.BankAccount d
			EXCEPT 
			SELECT d.FanID, d.[Value]
			FROM (
				SELECT FanID, [value], 
					rn = ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY [Date] DESC) 
				FROM ' + @TargetTableName + ' 
				WHERE TableColumnsID = ' + convert(varchar(10),@TableColumnsID) + '
			) d
			WHERE rn = 1
		) d'

ELSE IF @TableName = 'IssuerBankAccount'
	SELECT @query = 
		'INSERT INTO ' + @TargetTableName + ' (TableColumnsID, FanID, [Date], [Value])
		SELECT ' + convert(varchar(10),@TableColumnsID) + ', d.ID, ''' + convert(varchar(50),@Now)  + ''', d.' + @ColumnName + '
		FROM (
			SELECT d.ID, d.' + @ColumnName + '
			FROM SLC_Report.dbo.IssuerBankAccount d
			EXCEPT 
			SELECT d.FanID, d.[Value]
			FROM (
				SELECT FanID, [value], 
					rn = ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY [Date] DESC) 
				FROM ' + @TargetTableName + ' 
				WHERE TableColumnsID = ' + convert(varchar(10),@TableColumnsID) + '
			) d
			WHERE rn = 1
		) d'



-- populate ChangeLogtable		
IF @TargetTableName IN ('ChangeLog.DataChangeHistory_Nvarchar', 'ChangeLog.DataChangeHistory_Int', 
	'ChangeLog.DataChangeHistory_Tinyint', 'ChangeLog.DataChangeHistory_Datetime', 'ChangeLog.DataChangeHistory_Bit', 
	'ChangeLog.DataChangeHistory_Varchar', 'ChangeLog.DataChangeHistory_Smallmoney', 'ChangeLog.DataChangeHistory_Date')
	EXEC(@query)

