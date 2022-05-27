
/*
Author:		Stuart Barnley
Date:		25th September 2015
Purpose:	Used to build a table of customers who have never earned Rewards at a partner or by 
			addtionalcashbackawards (currently Contactless, CreditCard, Direct Debit)

Notes:		
*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_Never_Earned]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Customer_Never_Earned',
		TableSchemaName = 'Relational',
		TableName = 'Customer_Never_Earned',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

Truncate Table Relational.Customer_Never_Earned
/*--------------------------------------------------------------------------------------------------
-----------------------------Customers who have Earned----------------------------------------------
----------------------------------------------------------------------------------------------------*/
Select a.FanID
Into #Earners
From (
select c.FanID
from Relational.customer as c
inner join relational.PartnerTrans as pt
	on c.fanid = pt.FanID
Union
select c.FanID
from Relational.customer as c
inner join Relational.AdditionalCashbackAward as aca
	on c.fanid = aca.FanID
) as a
/*--------------------------------------------------------------------------------------------------
-----------------------------Customers who have Never Earned----------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert Into Relational.Customer_Never_Earned
Select c.FanID
from Relational.Customer as c
left Outer join #Earners as e
	on c.fanid = e.fanid
Where e.fanid is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Customer_Never_Earned' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_Never_Earned' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Customer_Never_Earned)
where	StoredProcedureName = 'WarehouseLoad_Customer_Never_Earned' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_Never_Earned' and
		TableRowCount is null
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp