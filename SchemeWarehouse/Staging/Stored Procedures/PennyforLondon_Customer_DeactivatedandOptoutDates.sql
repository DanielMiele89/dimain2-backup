CREATE Procedure [Staging].[PennyforLondon_Customer_DeactivatedandOptoutDates]
WITH EXECUTE AS OWNER
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'PennyforLondon_DeactivatedandOptoutDates',
		TableSchemaName = 'Staging',
		TableName = 'Customer_Activate_Deactivate',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

Declare @RowCount int
Set @RowCount = (Select Count(1) from [Staging].[Customer_Activate_Deactivate])
/*--------------------------------------------------------------------------------------------------
---------------------------Write entry to Table - Customers who deactivated-------------------------
----------------------------------------------------------------------------------------------------*/
Insert into [Staging].[Customer_Activate_Deactivate]
select	c.FanID,
		c.ClubID,
		c.ActivatedDate,
		Cast(dateadd(day,-1,getdate()) as Date) as DeactivatedDate,
		Case
			When f.OptOut = 1 then Cast(dateadd(day,-1,getdate()) as Date)
			Else NULL
		End as Optout_Date
from Relational.Customer as c
inner join slc_report.dbo.fan as f
	on	c.FanID = f.ID and
		c.ClubID = f.ClubID
Where c.CurrentlyActive = 1 and
		(f.AgreedTCs = 0 or f.Status = 0 or f.AgreedTCsDate is null)
/*--------------------------------------------------------------------------------------------------
----------------------Write entry to Table - Customers who activated and deactivated----------------
----------------------------------------------------------------------------------------------------*/
Insert into [Staging].[Customer_Activate_Deactivate]
Select	f.ID as FanID,
		f.ClubID,
		Cast(dateadd(day,-1,getdate()) as Date) as ActivatedDate,
		Cast(dateadd(day,-1,getdate()) as Date) as DeactivatedDate,
		Case
			When f.OptOut = 1 then Cast(dateadd(day,-1,getdate()) as Date)
			Else NULL
		End as Optout_Date
from slc_Report.dbo.fan as f
left outer join Relational.Customer as c
	on f.id = c.fanid
left outer join [Staging].[Customer_WarehouseExclusions] as we
	on f.id = we.FanID
inner join Relational.club as a
	on f.ClubID = a.ClubID
Where	(f.AgreedTCs = 0 or f.Status = 0 or f.AgreedTCsDate is null) and
		c.FanID is null and
		we.fanid is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'PennyforLondon_DeactivatedandOptoutDates' and
		TableSchemaName = 'Staging' and
		TableName = 'Customer_Activate_Deactivate' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select Count(1) from [Staging].[Customer_Activate_Deactivate])-@RowCount
where	StoredProcedureName = 'PennyforLondon_DeactivatedandOptoutDates' and
		TableSchemaName = 'Staging' and
		TableName = 'Customer_Activate_Deactivate' and
		TableRowCount is null
	
Insert into Relational.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from Relational.JobLog_Temp

TRUNCATE TABLE Relational.JobLog_Temp
