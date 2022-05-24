Create Procedure Staging.Tables_Truncate (@TableName varchar(150))
with Execute as owner
AS

Declare @User varchar(30)

Set @User = (Select User)

If @TableName in (Select Tablename From Staging.DataOperations_OwnerRights_Tables) and
   		@User in (Select UserName from Staging.DataOperations_OwnerRights_Users)

Begin
	Declare @Qry nvarchar(Max)
	Set @Qry = 'Truncate Table '+@TableName
	Exec sp_executeSQL @Qry
End