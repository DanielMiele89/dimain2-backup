CREATE Procedure Staging.Tables_IndexDisable (@TableName varchar(150),@IndexName varchar(100) )
with Execute as owner
AS

If @TableName in (Select Tablename From Staging.DataOperations_OwnerRights_Tables)

Begin
	Declare @Qry nvarchar(Max)
	Set @Qry = 'ALTER INDEX '+@IndexName+' ON '+@TableName+' DISABLE'
	Exec sp_executeSQL @Qry
	Select 'Table Index Disabled' + @IndexName
End