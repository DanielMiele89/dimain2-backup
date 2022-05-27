CREATE Procedure [Staging].[PennyforLondon_PartnerTrans_TFL]
WITH EXECUTE AS OWNER
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'PennyforLondon_PartnerTrans_TFL',
		TableSchemaName = 'Relational',
		TableName = 'PartnerTrans',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
------------------------------------Populate TFL entries--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Truncate table Relational.PartnerTrans
Insert into Relational.PartnerTrans
select	NULL							as MatchID,
		c.FanID							as FanID,
		0000							as PartnerID,
		0000							as OutletID,
		t.Price							as TransactionAmount,
		cast(t.[Date] as date)			as TransactionDate,
		cast(t.ProcessDate as date)		as AddedDate,
		Cast(Case 
				when t.ClubCash IS null then 0
				Else t.ClubCash * tt.Multiplier
			 End as SmallMoney) as CashBackEarned
from [Relational].[Customer] as c
inner join slc_report.dbo.Trans as t
	on c.FanID = t.FanID
inner join slc_report.dbo.TransactionType as tt
	on t.TypeID = tt.ID
Where VectorID = 39 and typeid in (19,18)

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'PennyforLondon_PartnerTrans_TFL' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerTrans' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.PartnerTrans)
where	StoredProcedureName = 'PennyforLondon_PartnerTrans_TFL' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerTrans' and
		TableRowCount is null

Insert into relational.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from relational.JobLog_Temp

TRUNCATE TABLE relational.JobLog_Temp
