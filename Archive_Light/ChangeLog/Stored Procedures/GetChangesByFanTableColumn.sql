
CREATE proc [ChangeLog].[GetChangesByFanTableColumn]
	@FanID int,
	@TableColumnsID int
as

set nocount on

declare 
	@query varchar(2048),
	@TableName varchar(50),
	@ColumnName varchar(50),
	@Datatype varchar(20),
	@TargetTableName varchar(50)

select 
	@TableName = TableName,
	@ColumnName = ColumnName,
	@Datatype = Datatype 
from ChangeLog.TableColumns where ID = @TableColumnsID


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


select @query = 
	'select Date as ChangedDate, Value as ' + @ColumnName + 
	' from ' + @TargetTableName + ' with (nolock) where FanID = ' + CONVERT(varchar(10),@FanID) + 
	' and TableColumnsID = ' + convert(varchar(10),@TableColumnsID) + 
	' order by Date desc'

exec(@query)

