
CREATE Procedure [Staging].[PennyforLondon_RedeemItems]
WITH EXECUTE AS OWNER
As
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_RedeemItems',
		TableSchemaName = 'Relational',
		TableName = 'RedemptionItem',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

-------------------------------------------------------------------------------------
---------------Insert Suggested Redemptions in RedemptionItem Table------------------
-------------------------------------------------------------------------------------
TRUNCATE TABLE Relational.RedemptionItem

Insert Into Relational.RedemptionItem
Select	Distinct
		r.ID as RedemptionID,
		1 as Donation,
        r.Privatedescription as RedemptionDescription
from	Relational.Customer c
join SLC_Report.dbo.Trans t 
	on t.FanID = c.FanID
join SLC_Report.dbo.Redeem r 
	on r.id = t.ItemID
where t.TypeID=3
Order by r.ID,r.Privatedescription

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_RedeemItems' and
		TableSchemaName = 'Relational' and
		TableName = 'RedemptionItem' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.RedemptionItem)
where	StoredProcedureName = 'Penny4London_RedeemItems' and
		TableSchemaName = 'Relational' and
		TableName = 'RedemptionItem' and
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

Truncate Table Relational.JobLog_Temp

End
