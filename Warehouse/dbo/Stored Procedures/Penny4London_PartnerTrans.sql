

Create PROCEDURE dbo.Penny4London_PartnerTrans
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into dbo.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_PartnerTrans',
	TableSchemaName = 'dbo',
	TableName = 'PartnerTrans',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'R'

/*--------------------------------------------------------------------------*/
/*--------------Extract Data from SLC_Report - Start - PartnerTrans---------*/
/*--------------------------------------------------------------------------*/
--Build PartnerTrans table. This represents transactions made with our partners.

Declare @ChunkSize int, @StartRow bigint, @FinalRow bigint, @StagingRow bigint, @RelationalRow bigint

Set @ChunkSize = 500000
Set @StartRow = 0
Set @FinalRow = (Select Max(MatchID)
		 		 from	SLC_Dev.dbo.Match m with (nolock)
				 inner join SLC_Dev.dbo.Pan p with (nolock) 
						on	p.ID = m.PanID and p.AffiliateID = 1
				 inner join dbo.Customer c with (nolock) 
						on	p.UserID = c.FanID
				 inner join SLC_Dev.dbo.Trans as t with (nolock)
						on	t.MatchID = m.ID and 
							c.FanID = t.FanID
				 inner join dbo.Outlet as o with (nolock)
						on	m.RetailOutletID = o.OutletID
				 Where	t.[status] = 1 and -- Eligible for Cashback
						rewardstatus in (0,1) -- Eligible for Cashback
				)

Truncate table dbo.PartnerTrans

Set @StagingRow = 0

While @FinalRow > @StagingRow
Begin

Insert into	dbo.PartnerTrans
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
from	SLC_Dev.dbo.Match m with (nolock)
		inner join SLC_Dev.dbo.Pan p with (nolock) 
				on p.ID = m.PanID and p.AffiliateID = 1  --Affiliate ID = 1 means this a scheme run by Reward (rather than e.g. Quidco)
		inner join dbo.Customer c with (nolock) 
				on	p.UserID = c.FanID and
					p.CompositeID = c.CompositeID
		inner join SLC_Dev.dbo.Trans as t with (nolock)
				on	t.MatchID = m.ID and 
					c.FanID = t.FanID
		inner join dbo.Outlet as o with (nolock)
				on	m.RetailOutletID = o.OutletID
		Left Outer Join SLC_Dev.dbo.TransactionType as tt
			on t.TypeID = tt.ID
Where	t.MatchID > @StartRow AND 
		t.MatchID <= @StartRow+@ChunkSize AND
		t.[status] = 1 and -- Eligible for Cashback
		rewardstatus in (0,1) -- Eligible for Cashback


Set @StartRow = @StartRow+@Chunksize
Set @StagingRow = isnull((Select Max (pt.MatchID) from dbo.PartnerTrans as pt with (nolock)),0)
END


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  dbo.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_PartnerTrans' and
		TableSchemaName = 'dbo' and
		TableName = 'PartnerTrans' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  dbo.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from dbo.PartnerTrans)
where	StoredProcedureName = 'Penny4London_PartnerTrans' and
		TableSchemaName = 'dbo' and
		TableName = 'PartnerTrans' and
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

TRUNCATE TABLE staging.JobLog_Temp

END

