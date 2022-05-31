
create proc [ChangeLog].[PopulateChangesForAll]
as
set nocount on

declare @TableColumnsID int

select @TableColumnsID = min(ID) from ChangeLog.TableColumns
while @TableColumnsID is not null
begin
	exec ChangeLog.PopulateChangesByTableColumnsID @TableColumnsID
	
	select @TableColumnsID = min(ID) from ChangeLog.TableColumns where ID > @TableColumnsID
end

