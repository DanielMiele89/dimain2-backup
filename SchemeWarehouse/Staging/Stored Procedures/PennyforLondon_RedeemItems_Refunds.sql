
CREATE Procedure [Staging].[PennyforLondon_RedeemItems_Refunds]
WITH EXECUTE AS OWNER
As
Begin

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_RedeemItems_Refunds',
		TableSchemaName = 'Relational',
		TableName = 'RedemptionItem',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

-------------------------------------------------------------------------------------
---------------Insert Suggested Redemptions in RedemptionItem Table------------------
-------------------------------------------------------------------------------------
Insert Into Relational.RedemptionItem
Select * from 
(Select		-1 as RedemptionItemID,
			0 as Donation,
			'Zero Down' as RedemptionDecription
Union All
Select		-2 as RedemptionItemID,
			0 as Donation,
			'Donation Refund' as RedemptionDecription
) as a
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_RedeemItems_Refunds' and
		TableSchemaName = 'Relational' and
		TableName = 'RedemptionItem' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = 2
where	StoredProcedureName = 'Penny4London_RedeemItems_Refunds' and
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
