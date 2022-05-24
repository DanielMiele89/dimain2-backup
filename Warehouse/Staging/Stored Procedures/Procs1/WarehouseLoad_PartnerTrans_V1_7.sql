/*
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of 
		the Warehouse database
Notes:		Amended to include TransactionWeekStartingCampaign in PartnerTrans which is a week starting 
		field based on Thursday being day one.
Update:		10/09/2014 - SC - Updated the Indexing to diasble and rebuild and added indexes to the Staging.PartnerTransTable
			03/11/2014 - SB - Updated to correctly mark as above base non-core partners
			25/11/2014 - SB - Updated to deal with CardHolderPresentData extending to varchar(2)
*/

CREATE PROCEDURE [Staging].[WarehouseLoad_PartnerTrans_V1_7]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7',
	TableSchemaName = 'Staging',
	TableName = 'PartnerTrans',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'R'
/*--------------------------------------------------------------------------*/
/*--------------------New Staging.PartnerTrans Primary Key------------------*/
/*--------------------------------------------------------------------------*/
/*
ALTER TABLE Staging.PartnerTrans
 ADD PRIMARY KEY (MatchID)
*/
/*--------------------------------------------------------------------------*/
/*--------------Extract Data from SLC_Report - Start - PartnerTrans---------*/
/*--------------------------------------------------------------------------*/
--Build PartnerTrans table. This represents transactions made with our partners.

Declare @ChunkSize int, @StartRow bigint, @FinalRow bigint, @StagingRow bigint, @RelationalRow bigint

Set @ChunkSize = 500000
Set @StartRow = 0
Set @FinalRow = (Select Max(MatchID)
		 		 from	SLC_Report.dbo.Match m with (nolock)
				 inner join SLC_Report.dbo.Pan p with (nolock) 
						on p.ID = m.PanID and p.AffiliateID = 1
				 inner join Relational.Customer c with (nolock) 
						on p.UserID = c.FanID
				 inner join slc_report.dbo.Trans as t with (nolock)
						on t.MatchID = m.ID and c.FanID = t.FanID)

Truncate table staging.PartnerTrans
--(Select Max (MatchID) from staging.PartnerTrans as pt)
--Set @RelationalRow = isnull((Select Max (MatchID) from Relational.PartnerTrans as pt with (nolock)),0)
Set @StagingRow = 0
--Delete from Warehouse.staging.PartnerTrans

While @FinalRow > @StagingRow
Begin

Insert into	Staging.PartnerTrans
select	m.ID							as MatchID,
		c.FanID							as FanID,
		cast(m.TransactionDate as date)	as TransactionDate,
		cast(m.AddedDate as date)		as AddedDate,
		m.RetailOutletID				as OutletID,
		m.Amount						as TransactionAmount,
		m.status						as status,			
		m.PartnerCommissionRuleID		as PartnerCommissionRuleID,
		m.rewardstatus					as rewardstatus,
		m.AffiliateCommissionAmount		as AffiliateCommissionAmount,
		Cast(null as Integer)										 as PartnerID,
		CAST(null as Date)											 as TransactionWeekStarting,
		CAST(null as tinyint)										 as TransactionMonth,
		CAST(Null as smallint)										 as TransactionYear,
		CAST(null as Date)											 as TransactionWeekStartingCampaign,--new field to hold Thursday equivalent of TransactionWeekStarting
		CAST(Null as Date)											 as AddedWeekStarting,
		CAST(null as tinyint)										 as AddedMonth,
		Cast(null AS smallint)										 as AddedYear,
		CAST(null as bit)											 as ExtremeValueFlag,
	 	CAST(null as Bit)											 as IsOnline,
	 	Left(Coalesce(m.CardHolderPresentData,MCHP.CardholderPresentData),1) as CardHolderPresentData,
		CAST(null as Bit)											 as EligibleForCashBack,
		CAST(null as Money)											 as CommissionChargable,
		CAST(null as Money)											 as CashbackEarned,
		CAST(null as Int)											 as IronOfferID,
		CAST(t.ActivationDays as Int)								 as ActivationDays,
		CAST(Null as Int)											 as AboveBase
from	SLC_Report.dbo.Match m with (nolock)
		inner join SLC_Report.dbo.Pan p with (nolock) 
				on p.ID = m.PanID and p.AffiliateID = 1  --Affiliate ID = 1 means this a scheme run by Reward (rather than e.g. Quidco)
		inner join Relational.Customer c with (nolock) 
				on p.UserID = c.FanID
		inner join slc_report.dbo.Trans as t with (nolock)
				on t.MatchID = m.ID and c.FanID = t.FanID
		Left Outer join staging.MatchCardHolderPresent as MCHP
			on t.MatchID = MCHP.MatchID
--where 	f.ClubID = 132	
Where t.MatchID > @StartRow AND t.MatchID <= @StartRow+@ChunkSize
Set @StartRow = @StartRow+@Chunksize
Set @StagingRow = isnull((Select Max (pt.MatchID) from Staging.PartnerTrans as pt with (nolock)),0)
END


/*--------------------------------------------------------------------------*/
/*--------------Enhance Data in Staging - Start - PartnerTrans--------------*/
/*--------------------------------------------------------------------------*/
set datefirst 1	--set the first day of the week to Monday. This influences the return value of datepart()
update	t
set		t.PartnerID = p.PartnerID,
		t.TransactionWeekStarting = dateadd(dd, - 1 * (datepart(dw, TransactionDate) - 1) , TransactionDate),
		t.TransactionMonth = month(TransactionDate),
		t.TransactionYear = year(TransactionDate),
		t.TransactionWeekStartingCampaign =
		Case
			When dateadd(dd,3,dateadd(dd, - 1 * (datepart(dw, TransactionDate) - 1) , TransactionDate)) > TransactionDate then
				dateadd(dd,-4,dateadd(dd, - 1 * (datepart(dw, TransactionDate) - 1) , TransactionDate))
			Else dateadd(dd,3,dateadd(dd, - 1 * (datepart(dw, TransactionDate) - 1) , TransactionDate))
		End,
		t.AddedWeekStarting = dateadd(dd, - 1 * (datepart(dw, AddedDate) - 1) , AddedDate),
		t.AddedMonth = month(AddedDate),
		t.AddedYear = year(AddedDate),
		t.ExtremeValueFlag = 0,
		t.IsOnline = 
		Case 
			When p.partnerID = 3724 and o.Channel = 1 then 1
			when t.CardholderPresentData = '5' then 1
			When t.CardholderPresentData = '9' and o.Channel = 1 then 1
			else 0 
		end,
		--t.CardHolderPresentData = MCHP.CardholderPresentData,
		t.EligibleForCashBack = case when t.[status] = 1 and rewardstatus in (0,1) then 1 else 0 end,
		t.CommissionChargable = case when t.[status] = 1 and rewardstatus in (0,1) then 1 else 0 end * AffiliateCommissionAmount,
		t.CashbackEarned = 
		Case
			When CBEarned.CashBackEarned IS null then 0
			Else CBEarned.CashBackEarned
		End,
		t.IronOfferID = pcr.RequiredIronOfferID
from	staging.PartnerTrans t 
		inner join staging.Outlet o on t.OutletID = o.OutletID
		inner join relational.Partner p on p.PartnerID = o.PartnerID
		Left outer join 
		(Select Distinct MatchID,
				Case 
					when t.ClubCash IS null then 0
					Else t.ClubCash * tt.Multiplier
				End as CashBackEarned
		 from SLC_Report.dbo.Trans as t
		inner join SLC_Report.dbo.TransactionType as tt
			on t.TypeID = tt.ID
		) as CBEarned
			on t.MatchID = CBEarned.MatchID
		Left outer join slc_report.dbo.PartnerCommissionRule pcr 
			on t.PartnerCommissionRuleID = pcr.ID and pcr.TypeID = 2 and (t.[status] = 1 and rewardstatus in (0,1))
		--INNER join staging.MatchCardHolderPresent as MCHP
		--	on t.MatchID = MCHP.MatchID
			
delete from staging.PartnerTrans where PartnerID is null

--Flag the extreme values on the transactions
if object_id('tempdb..#temp1') is not null drop table #temp1

select	t.MatchID,
		t.PartnerID,
		t.TransactionAmount,
		ntile(100) over (partition by PartnerID order by TransactionAmount) ValuePercentile
into	#temp1
from	staging.PartnerTrans t with (nolock)
order by PartnerID

update	tr
set		tr.ExtremeValueFlag = 1
from	staging.PartnerTrans tr
		inner join #temp1 te on tr.MatchID = te.MatchID
where	te.ValuePercentile in (1,2,3,4,5,96,97,98,99,100)		--Top and bottom 5% of transactions are flagged as extreme values

drop table #temp1	--clean up



---------------------------------------------------------------------------------------------------------------------
------------------------------------------Calculating the Above Base Field-------------------------------------------
---------------------------------------------------------------------------------------------------------------------
--Work Out above base or not Pre Launch
--This section adds a customer segment and the base cashback rate IF the transactions meets the where clause 
if object_id ('tempdb..#PtSeg') is not null drop table #PtSeg
SELECT	pt.MatchID,
	Cast(CASE	
				WHEN CashBackEarned > 0 and CashbackEarned > Cast(TransactionAmount * (pb.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
				WHEN CashBackEarned < 0 and CashbackEarned < Cast(TransactionAmount * (pb.CashBackRateNumeric+0.005) AS NUMERIC(36,2)) THEN 1
				ELSE 0
	END as Int) as AboveBase
Into #PtSeg
FROM staging.partnertrans as pt with (nolock)
Inner join Relational.Customer_Segment cs with (nolock)
	ON pt.FanID = cs.FanID
	AND pt.PartnerID = cs.PartnerID
Inner JOIN Relational.Partner_BaseOffer pb with (nolock)
	ON cs.OfferID = pb.OfferID
WHERE (	(TransactionDate >= pb.StartDate AND pb.EndDate IS NULL) OR 
		(TransactionDate >= pb.StartDate AND TransactionDate <= pb.EndDate)
	  ) and
		pt.EligibleForCashBack = 1 and 
		CashbackEarned <> 0
--(2570883 row(s) affected)
--20 secs
----------------------------------------------------------------------
---------Work Out above base or not Post Launch-----------------------
----------------------------------------------------------------------
--This adds a cashback rate if the transaction is post launch
if object_id ('tempdb..#PTWithPostLaunchCBR') is not null drop table #PTWithPostLaunchCBR
SELECT	Distinct
		pt.MatchID,
		Cast(CASE	
				WHEN CashBackEarned > 0 and 
									CashbackEarned > Cast(TransactionAmount * (po.CashBackRateNumeric+0.005) AS NUMERIC(36,2))
				THEN 1
				WHEN CashBackEarned < 0 and
									CashbackEarned < Cast(TransactionAmount * (po.CashBackRateNumeric+0.005) AS NUMERIC(36,2))
				THEN 1
				ELSE 0
			 END as Int) as AboveBase
INTO #PTWithPostLaunchCBR
FROM staging.partnertrans as pt with (nolock)
Inner join Relational.PartnerOffers_Base po  with (nolock)
	ON pt.PartnerID = po.PartnerID AND TransactionDate >= po.StartDate AND 
		(po.EndDate IS NULL OR TransactionDate <= po.EndDate) and 
		EligibleForCashBack = 1 and CashbackEarned <> 0
LEFT OUTER JOIN #PtSeg AS PTSEG
	ON PT.MatchID = PTSeg.MatchID
Where PTSeg.MatchID is null

--Select * from #PTWithPostLaunchCBR
--Select * from #PTseg
--Where matchid = 102253777
--(0 row(s) affected)
----------------------------------------------------------------------
-----------------Combine two tables together--------------------------
----------------------------------------------------------------------

if object_id ('tempdb..#PTWithAB') is not null drop table #PTWithAB
Select * 
Into #PTWithAB
from 
(SELECT	*
From #PtSeg
union all
Select * 
from #PTWithPostLaunchCBR
) as a
----------------------------------------------------------------------
-----------------drop two tables--------------------------
----------------------------------------------------------------------
Drop Table #PtSeg
Drop table #PTWithPostLaunchCBR


Update staging.PartnerTrans
Set Abovebase = pt.AboveBase
FROM staging.PartnerTrans p
LEFT OUTER JOIN #PTWithAB pt
ON p.MatchID = pt.MatchID


---------------------------------------------------------------------------------------------
-----------------Set Above Base to 1 for all non coalition partners--------------------------
---------------------------------------------------------------------------------------------

Update staging.PartnerTrans
Set Abovebase = 1
Where	PartnerID in (Select PartnerID from [Relational].[Partner_CBPDates] Where [Coalition_Member] = 0) and
		AboveBase is null
---------------------------------------------------------------------------------------------
-----------------Delete not eligible for cashback transactions-------------------------------
---------------------------------------------------------------------------------------------
Delete from staging.partnertrans
Where Eligibleforcashback = 0



/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7' and
		TableSchemaName = 'Staging' and
		TableName = 'PartnerTrans' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.PartnerTrans)
where	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7' and
		TableSchemaName = 'Staging' and
		TableName = 'PartnerTrans' and
		TableRowCount is null
		
		
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7',
	TableSchemaName = 'Relational',
	TableName = 'PartnerTrans',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'R'
/*--------------------------------------------------------------------------*/
/*--------------------New Staging.PartnerTrans Primary Key------------------*/
/*--------------------------------------------------------------------------*/
/*
ALTER TABLE Relational.PartnerTrans
 ADD PRIMARY KEY (MatchID)
*/	

/*--------------------------------------------------------------------------*/
/*--------------Build final tables in relational schema -PartnerTrans-------*/
/*--------------------------------------------------------------------------*/

--if object_id('Relational.PartnerTrans') is not null drop table Relational.PartnerTrans
--delete from Relational.PartnerTrans

ALTER INDEX i_FanID ON Relational.PartnerTrans  DISABLE
ALTER INDEX i_TranAssessment ON Relational.PartnerTrans  DISABLE
ALTER INDEX i_TransactionWeekStarting ON Relational.PartnerTrans  DISABLE

Truncate table Relational.PartnerTrans

--Declare @ChunkSize int, @StartRow bigint, @FinalRow bigint, @RelationalRow bigint
--Set @ChunkSize = 500000
Set @StartRow = 0
Set @FinalRow = (Select Max (MatchID) from staging.PartnerTrans as pt with (nolock))
Set @RelationalRow = isnull((Select Max (MatchID) from Relational.PartnerTrans as pt with (nolock)),0)

--Select @ChunkSize, @StartRow, @FinalRow, @RelationalRow

While @FinalRow > @RelationalRow
Begin

Insert into	Relational.PartnerTrans
select	MatchID,
		FanID,
		PartnerID,
		OutletID,
		IsOnline,
		CardHolderPresentData,
		TransactionAmount,
		ExtremeValueFlag,
		TransactionDate,
		TransactionWeekStarting,
		TransactionMonth,
		TransactionYear,
		TransactionWeekStartingCampaign,
		AddedDate,
		AddedWeekStarting,
		AddedMonth,
		AddedYear,
		status,
		rewardstatus,
		AffiliateCommissionAmount,
		EligibleForCashBack,
		CommissionChargable,
		CashbackEarned,
		IronOfferID,
		ActivationDays,
		AboveBase,
		0 as PaymentMethodID
from	staging.PartnerTrans with (nolock)
Where MatchID > @StartRow AND MatchID <= @StartRow+@ChunkSize
Set @StartRow = @StartRow+@Chunksize
Set @RelationalRow = isnull((Select Max (MatchID) from Relational.PartnerTrans as pt with (nolock)),0)
END

--Rebuild Indexes
ALTER INDEX i_FanID ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE)
ALTER INDEX i_TranAssessment ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE)
ALTER INDEX i_TransactionWeekStarting ON Relational.PartnerTrans  REBUILD WITH (DATA_COMPRESSION = PAGE)

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7' and
		TableSchemaName = 'Relational' and
		TableName = 'PartnerTrans' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.PartnerTrans)
where	StoredProcedureName = 'WarehouseLoad_PartnerTrans_V1_7' and
		TableSchemaName = 'Relational' and
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



