
CREATE Procedure Staging.WarehouseLoad_Customer_Registered_MI
As

truncate table staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Customer_Registered_MI',
		TableSchemaName = 'Relational',
		TableName = 'Customer_Registered',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
/*--------------------------------------------------------------------------------------------------
-----------------------------Count Rows in Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Declare @RowCount int
Set @RowCount = (Select Count(*) from Relational.Customer_Registered)
/*--------------------------------------------------------------------------------------------------
-----------------------Create initial list of customer marketing preferences------------------------
----------------------------------------------------------------------------------------------------*/

Declare @MaxFanID int,@Chunksize int,@FanID int
Set @MaxFanID = (Select Max(FanID) from Relational.Customer as c)
Set @ChunkSize = 250000
Set @FanID = 0

Create Table #Cust (FanID int, Registered Bit,Primary Key (FanID))

While @FanID < @MaxFanID
Begin
	Insert into #Cust
	Select	Top (@ChunkSize)
			c.FanID,
			Cast(c.Registered as Bit) as Registered
	from Relational.Customer as c
	Where FanID > @FanID
	Order by FanID

	Set @FanID = (Select Max(FanID) from #Cust)
End
/*--------------------------------------------------------------------------------------------------
--------------------------------------------End Date old Entries------------------------------------
----------------------------------------------------------------------------------------------------*/
Update Relational.Customer_Registered
Set EndDate = dateadd(day,-1,Cast(getdate()as date))
from #Cust as c
inner join Relational.Customer_Registered as m
	on	c.fanid = m.fanid and
		m.EndDate is null and
		m.Registered <> c.Registered
/*--------------------------------------------------------------------------------------------------
--------------------------------------------Create New Entries------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.Customer_Registered
Select	c.FanID,
		c.Registered,
		StartDate = Cast(getdate()as date),
		EndDate = Cast(Null as date)
from #Cust as c
Left Outer join Relational.Customer_Registered as m
	on	c.fanid = m.fanid and
		m.EndDate is null and
		m.Registered = c.Registered
Where m.Fanid is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Customer_Registered_MI' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_Registered' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Customer_Registered)-@RowCount
where	StoredProcedureName = 'WarehouseLoad_Customer_Registered_MI' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_Registered' and
		TableRowCount is null

Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
truncate table staging.JobLog_Temp