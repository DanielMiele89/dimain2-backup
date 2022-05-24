CREATE Procedure Staging.Tables_ReIndex (@TableName varchar(150))
with Execute as owner
AS

If @TableName in (Select Tablename From Staging.DataOperations_OwnerRights_Tables)

Begin
	Declare @Qry nvarchar(Max)
	Set @Qry = 'ALTER INDEX ALL ON '+@TableName+' REBUILD'
	Exec sp_executeSQL @Qry
	Select 'Table Reindexed'
End