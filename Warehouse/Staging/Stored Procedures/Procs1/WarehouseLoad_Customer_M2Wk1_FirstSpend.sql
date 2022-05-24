CREATE Procedure Staging.WarehouseLoad_Customer_M2Wk1_FirstSpend
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_Customer_M2Wk1_FirstSpend',
		TableSchemaName = 'Relational',
		TableName = 'SFD_MOT3Wk1_PartnerSpend',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'
--Counts pre-population
DECLARE	@RowCount BIGINT
SET @RowCount = (SELECT COUNT(*) FROM Relational.SFD_MOT3Wk1_PartnerSpend with (nolock))

----------------------------------------------------------------------------------------------------------
--------------------Select customers who are MOT2 Week 1- based on SFD daily upload-----------------------
----------------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
select	a.FanID,
		c.ClubID,
		c.Email
Into #t1
from SLC_Report.[dbo].[FanSFDDailyUploadData] as a
inner join Relational.Customer as c
	on a.FanID = c.FanID
Where	CJS = 'M2' and 
		WeekNumber = 1 and
		MarketableByEmail = 1

----------------------------------------------------------------------------------------------------------
----------------------------- Delete those who are not Marketable By Email -------------------------------
----------------------------------------------------------------------------------------------------------
Delete from #t1
From #t1 as t
inner join Relational.CustomerPaymentMethodsAvailable as cpma
	on	t.FanID = cpma.FanID and
		cpma.EndDate is null and
		cpma.PaymentMethodsAvailableID = 3
----------------------------------------------------------------------------------------------------------
------------------------------------- Delete those who are not in NLSC -----------------------------------
----------------------------------------------------------------------------------------------------------
Delete from #t1
from #t1 as t
left outer join 
(Select Distinct t.FanID
from Warehouse.Lion.NominatedLionSendComponent as nlsc
inner join Warehouse.Relational.Customer as c
	on nlsc.CompositeId = c.CompositeID
Inner join #t1 as t
	on c.FanID = t.fanID
) as a
	on t.FanID = a.FanID
Where a.FanID is null
----------------------------------------------------------------------------------------------------------
-------------------------------------- Create Clustered Index --------------------------------------------
----------------------------------------------------------------------------------------------------------
Create Clustered Index ix_t1_FanID on #t1 (FanID)

----------------------------------------------------------------------------------------------------------
------------------------------- Find date of Transactions with Partners ----------------------------------
----------------------------------------------------------------------------------------------------------

if object_id('tempdb..#CustomerSpend') is not null drop table #CustomerSpend
Select	t.FanID,
		p.PartnerID,
		p.PartnerName,
		Min(Case
				When TransactionAmount > 0 then TransactionDate
				Else NULL
			End) as FirstTrans,
		Max(Case
				When TransactionAmount > 0 then TransactionDate
				Else NULL
			End) as LastTrans,
		Sum(TransactionAmount) as TotalSpend,
		Max(Case
				When TransactionAmount < 0 then 1
				Else 0
			End) as Negative
Into #CustomerSpend
from Relational.PartnerTrans as pt
inner join #t1 as t
	on pt.FanID = t.FanID
inner join Relational.Partner as p
	on pt.PartnerID = p.PartnerID
Group by t.FanID,
		p.PartnerID,
		p.PartnerName
----------------------------------------------------------------------------------------------------------
------------------------------------- Find date of last email --------------------------------------------
----------------------------------------------------------------------------------------------------------
Declare @LastSendDate date

Set @LastSendDate = (	Select Max(ec.SendDate)
						from Relational.CampaignLionSendIDs as cls
						inner join Relational.EmailCampaign as ec
							on cls.CampaignKey = ec.CampaignKey
					)

Set @LastSendDate = Case
						When @LastSendDate < DateAdd(day,-17,Getdate()) then DateAdd(day,-17,Getdate())
						Else @LastSendDate
					End
--Select @LastSendDate
----------------------------------------------------------------------------------------------------------
------------------------------------- Pick the valid partner Spend ---------------------------------------
----------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PartnerSpend') is not null drop table #PartnerSpend
Select * 
Into #PartnerSpend
from 
(
Select	cs.*,
		mrt.tier,
		ROW_NUMBER() OVER(PARTITION BY cs.FanID ORDER BY Tier ASC,
														 LastTrans Desc,
														 TotalSpend Desc) AS RowNo
From #CustomerSpend as cs
inner join relational.Master_Retailer_Table as mrt
	on cs.PartnerID = mrt.PartnerID
Where TotalSpend > 0 and FirstTrans > Dateadd(day,-2,@LastSendDate)
) as a
Order by LastTrans
----------------------------------------------------------------------------------------------------------
-------------------------------------- Find Contactless Spend --------------------------------------------
----------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Contactless') is not null drop table #Contactless
Select Distinct t.FanID,Min(AddedDate) as Firsttran
Into #Contactless
from #t1 as t
inner join warehouse.relational.AdditionalCashbackAward as aca
	on t.fanid = aca.fanid
Where AdditionalCashbackAwardTypeID = 1
Group by t.FanID
	Having Min(AddedDate) >= @LastSendDate

--Select * from #Contactless

----------------------------------------------------------------------------------------------------------
--------------------------------------- Create Combined List ---------------------------------------------
----------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers
Select	t.FanID,
		t.ClubID,
		t.Email,
		ps.PartnerID,
		Case 
			When c.FanID is not null then 1 
			else 0 
		End as Contactless
into #Customers
from #t1 as t
Left Outer join #PartnerSpend as ps
	on	t.fanid = ps.fanid and
		ps.RowNo = 1
Left Outer join #Contactless as c
	on t.FanID = c.FanID
----------------------------------------------------------------------------------------------------------
----------------------------------------- Delete if neither ----------------------------------------------
----------------------------------------------------------------------------------------------------------
Delete from #Customers
Where Contactless = 0 and PartnerID is null
----------------------------------------------------------------------------------------------------------
--------------------------------------- Create Combined List ---------------------------------------------
----------------------------------------------------------------------------------------------------------
Insert into Relational.SFD_MOT3Wk1_PartnerSpend
Select	FanID as [Customer ID],
		Case
			When c.PartnerID is null and Contactless = 1 then 'Contactless'
			When d.PartnerID is not null then d.PartnerName
			Else p.PartnerName
		End as LastSpend,
		Cast(getdate() as date) as [Date]
from #Customers as c
left outer join Staging.Partner_DynamicContentLabel as d
	on	c.PartnerID = d.Partnerid
Left Outer join Relational.Partner as p
	on c.partnerid = p.PartnerID
Order by LastSpend

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_Customer_M2Wk1_FirstSpend' and
		TableSchemaName = 'Relational' and
		TableName = 'SFD_MOT3Wk1_PartnerSpend' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.SFD_MOT3Wk1_PartnerSpend)-@RowCount
where	StoredProcedureName = 'WarehouseLoad_Customer_M2Wk1_FirstSpend' and
		TableSchemaName = 'Relational' and
		TableName = 'SFD_MOT3Wk1_PartnerSpend' and
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