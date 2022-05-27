

CREATE PROCEDURE [Staging].[PennyforLondon_Redemption]
WITH EXECUTE AS OWNER
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Redemption',
		TableSchemaName = 'Relational',
		TableName = 'Redemption',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
		
---------------------------------------------------------------------------------------------------------
--------------------Pull out a list of redemptions including those later cancelled-----------------------
---------------------------------------------------------------------------------------------------------
Truncate Table Relational.Redemption
Insert into Relational.Redemption
select	t.FanID,
		t.id as TranID,
		r.id as RedemptionItemID,
		Min(t.Date) as RedemptionDate,
		t.Price as CashbackUsed     
from  Relational.Customer c
inner join SLC_Report.dbo.Trans t on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r on r.id = t.ItemID
LEFT Outer JOIN (select ItemID as TransID from SLC_Report.dbo.trans t2 where t2.typeid=4) as Cancelled ON Cancelled.TransID=T.ID
inner join SLC_Report.dbo.RedeemAction ra on t.ID = ra.transid and ra.Status in (1,6)
where t.TypeID=3
	AND T.Points > 0
Group by t.FanID,r.id,t.id,t.Price,case when Cancelled.TransID is null then 0 else 1 end
order by TranID

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Redemption' and
		TableSchemaName = 'Relational' and
		TableName = 'Redemption' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Redemption)
where	StoredProcedureName = 'Penny4London_Redemption' and
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
