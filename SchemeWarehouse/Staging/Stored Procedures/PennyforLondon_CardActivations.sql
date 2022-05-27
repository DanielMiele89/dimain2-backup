
/*
 Author:			Stuart Barnley
 Date:				29/10/2014

 Description:		This stored procedure creates the CardActivations table

 Notes:

*/

CREATE Procedure [Staging].[PennyforLondon_CardActivations]
WITH EXECUTE AS OWNER
as
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_CardActivations',
		TableSchemaName = 'Relational',
		TableName = 'CardActivations',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
----------------------------------------------------------------------------------------
------------------------------Populate CardActivations table-----------------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.CardActivations
Insert into	Relational.CardActivations
select	p.ID as PanID,
		c.FanID,
		p.AdditionDate,
		p.RemovalDate,
		p.PaymentCardID
from Relational.customer as c
inner join SLC_Report.dbo.pan as p
	on	c.fanid = p.userid and
		c.CompositeID = p.CompositeID


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_CardActivations' and
		TableSchemaName = 'Relational' and
		TableName = 'CardActivations' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.CardActivations)
where	StoredProcedureName = 'Penny4London_CardActivations' and
		TableSchemaName = 'Relational' and
		TableName = 'CardActivations' and
		TableRowCount is null


Insert into Relational.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from Relational.JobLog_Temp

truncate table Relational.JobLog_Temp
End