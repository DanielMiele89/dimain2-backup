

CREATE PROCEDURE [Staging].[PennyforLondon_PartnerTrans]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'PennyforLondon_PartnerTrans',
	TableSchemaName = 'Relational',
	TableName = 'PartnerTrans',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'A'
/*--------------------------------------------------------------------------------------------------
-----------------------------Count Partner Trans Rows--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Declare @RowCount int
Set @RowCount = (Select Count(*) from Relational.PartnerTrans)
/*--------------------------------------------------------------------------*/
/*--------------Extract Data from SLC_Report - Start - PartnerTrans---------*/
/*--------------------------------------------------------------------------*/
--Build PartnerTrans table. This represents transactions made with our partners.

Declare @ChunkSize int, @StartRow bigint, @FinalRow bigint, @StagingRow bigint, @RelationalRow bigint

Set @ChunkSize = 500000
Set @StartRow = 0
Set @FinalRow = (Select Max(MatchID)
		 		 from	SLC_Report.dbo.Match m with (nolock)
				 inner join SLC_Report.dbo.Trans as t with (nolock)
					on	t.MatchID = m.ID
				 inner join Relational.Customer c with (nolock) 
					on	t.FanID = c.FanID
				 inner join Relational.Outlet as o with (nolock)
					on	m.RetailOutletID = o.OutletID
				 Left Outer Join SLC_Report.dbo.TransactionType as tt
					on t.TypeID = tt.ID
				 Where	m.[status] = 16 and -- Eligible for Cashback
						m.rewardstatus in (1) and-- Eligible for Cashback
						o.OutletID > 0
				)

--Truncate table Relational.PartnerTrans

Set @StagingRow = 0

While @FinalRow > @StagingRow
Begin

Insert into	Relational.PartnerTrans
select	m.ID							as MatchID,
		c.FanID							as FanID,
		o.PartnerID						as PartnerID,
		o.OutletID						as OutletID,
		m.Amount						as TransactionAmount,
		cast(m.TransactionDate as date)	as TransactionDate,
		cast(m.AddedDate as date)		as AddedDate,
		Cast(Case 
				when t.ClubCash IS null then 0
				Else t.ClubCash * tt.Multiplier
			 End as SmallMoney) as CashBackEarned
from	SLC_Report.dbo.Match m with (nolock)
		inner join SLC_Report.dbo.Trans as t with (nolock)
				on	t.MatchID = m.ID
		inner join Relational.Customer c with (nolock) 
				on	t.FanID = c.FanID
		inner join Relational.Outlet as o with (nolock)
				on	m.RetailOutletID = o.OutletID
		Left Outer Join SLC_Report.dbo.TransactionType as tt
			on t.TypeID = tt.ID
Where	t.MatchID > @StartRow AND 
		t.MatchID <= @StartRow+@ChunkSize AND
		m.[status] = 16 and -- Eligible for Cashback
		m.rewardstatus in (1) and-- Eligible for Cashback
		o.OutletID > 0


Set @StartRow = @StartRow+@Chunksize
Set @StagingRow = isnull((Select Max (pt.MatchID) from Relational.PartnerTrans as pt with (nolock)),0)
END


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'PennyforLondon_PartnerTrans' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerTrans' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.PartnerTrans)-@RowCount
where	StoredProcedureName = 'PennyforLondon_PartnerTrans' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerTrans' and
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
