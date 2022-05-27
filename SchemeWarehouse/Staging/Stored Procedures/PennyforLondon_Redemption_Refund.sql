

CREATE PROCEDURE [Staging].[PennyforLondon_Redemption_Refund]
WITH EXECUTE AS OWNER
AS
BEGIN
Declare @RowCount int
Set @RowCount = (Select Count(*) from Relational.Redemption)
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Redemption_Refund',
		TableSchemaName = 'Relational',
		TableName = 'Redemption',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
		
---------------------------------------------------------------------------------------------------------
--------------------Pull out a list of redemptions including those later cancelled-----------------------
---------------------------------------------------------------------------------------------------------

Insert into Relational.Redemption
select	t.FanID,
		t.id as TranID,
		Case
			When T.TypeID = 18 then -1
			Else -2
		End as RedemptionItemID,
		t.Date as RedemptionDate,
		(Case
			When t.TypeID = 20 then 1
			Else -1
		End) * 
		t.ClubCash as CashbackUsed
from  Relational.Customer c
inner join SLC_Report.dbo.Trans t on t.FanID = c.FanID
where t.TypeID in (18,20)
	  and t.ClubCash <> 0
order by TranID

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Redemption_Refund' and
		TableSchemaName = 'Relational' and
		TableName = 'Redemption' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Redemption)-@RowCount
where	StoredProcedureName = 'Penny4London_Redemption_Refund' and
		TableSchemaName = 'Relational' and
		TableName = 'Redemption' and
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

END
