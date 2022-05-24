

Create Procedure [Staging].[CBP_Process_CustomerJourneyStages_SpecificDates]
					  @RowNo int,
					  @interval int,
					  @Today Date
					--@EndDate date,
					--@TableName nvarchar(150)
as
Begin
set nocount on
--Declare @Today datetime
--set @Today = getdate()
------------------------------------------------------------------------------------------------------------
------------------------------------------------CustomerBase------------------------------------------------
------------------------------------------------------------------------------------------------------------
--Create a Customer Table of Currently Active FanIDs
Select FanID, ActivatedDate
Into #CB
from ##Cust
Where RowNumber Between @RowNo and @RowNo+(@Interval-1)
/*from dbo.fan as f with (nolock)
Where	f.clubid in (132,138) and 
		f.AgreedTCsDate is not null and 
		f.Status = 1
*/
Create Clustered index ixc_CB on #CB(FanID)
------------------------------------------------------------------------------------------------------------
------------------------------------------Pull the Transactions---------------------------------------------
------------------------------------------------------------------------------------------------------------
--Pull rolling totals for spend ever based on cashback earned on transactions or discretionary amounts awarded
select	--top 1000
		t.FanID as FanID,
		t.[Date],
		t.ClubCash*tt.Multiplier as CashBack, --Cashback Earned
		Dateadd(day,t.ActivationDays,t.[Date]) as DateAvailable,
		Case
			When Dateadd(day,t.ActivationDays,t.[Date]) <= @Today then t.ClubCash*tt.Multiplier
			else 0
		End as CashBackAvailable, --Cashback available for use
		Sum(Case
				When Dateadd(day,t.ActivationDays,t.[Date]) <= @Today then t.ClubCash*tt.Multiplier
				else 0
			End) 
			Over (Partition By t.FanID Order By Dateadd(day,t.ActivationDays,t.[Date])) as RT,  --Running total based on cashback available (not pending)
		ROW_NUMBER() OVER(PARTITION BY t.FanID ORDER BY Dateadd(day,t.ActivationDays,t.[Date])) AS RowNo

Into #Trans
from #CB as f
inner join SLC_Report.dbo.trans as t with (nolock)
	on f.FanID = t.FanID
Inner join SLC_Report.dbo.TransactionType as TT with (noLock)
	on t.TypeID = TT.ID
Where	t.TypeID in (1,9,10,17) -- Cashback earned/removed from Transaction or Cashback awarded/removed by call centre
		and t.ProcessDate < @Today
		 
Create Clustered index ixc_Trans on #Trans(FanID)

------------------------------------------------------------------------------------------------------------
--------------------------------------------------MOT1 and MOT2---------------------------------------------
------------------------------------------------------------------------------------------------------------
--Assign members to MOT1 (never earned cashback with partner) and MOT2 (not enough available cashback ever gained to redeem).
Select	FanID,
		Case
			When Sum(CashBack) <= 0 then 'MOT1'  -- Once a customer has some pending they move to MOT2
			When Sum(CashBackAvailable) <  5 then 'MOT2' --not enough available cashback ever gained to redeem (will need to review for microburn)
			When Sum(CashBackAvailable) >= 5 then '?' --enough gained to redeem
		End as CJ_Status
Into #CJ1
From #Trans
group by FanID

Create clustered index ixc_CJ1 on #CJ1(FanID)
------------------------------------------------------------------------------------------------------------
--------------------------------------------------MOT3 and Saver---------------------------------------------
------------------------------------------------------------------------------------------------------------
--if customer has gained over £5 available cashback ever we are checking how long they have had it.
Select	a.FANID,
		Case
			When t.DateAvailable < dateadd(day,-20,cast(getdate() as date)) then 'Saver'
			Else 'MOT3'
		End as CJ_Status
into #cj2
from 
(Select	cj1.FaniD,
		Max(Case
				When RT < 5 then RowNo
				Else 0
			End)+1 as [5Pounds]
from #Cj1  as cj1
inner join #Trans as t
	on cj1.FanID = t.FanID
Where CJ_Status = '?'
Group by cj1.FanID
) as a
inner join #Trans as t
	on	a.fanid = t.fanid and
		a.[5Pounds] = t.RowNo

Create Clustered index ixc_cj2 on #cj2(FanID)
------------------------------------------------------------------------------------------------------------
-----------------------------------------Produce a list of Redemptions--------------------------------------
------------------------------------------------------------------------------------------------------------
--Pull a list of redemptions
select	t.FanID,
		t.id as TranID,
        t.Date as RedeemDate,
        r.Description as PrivateDescription,
        t.Price,            
        case when Cancelled.TransID is null then 0 else 1 end Cancelled
into	#Redemptions        
from  #CB as c with (nolock)
inner join SLC_Report.dbo.Trans as t with (nolock)
	on t.FanID = c.FanID
inner join SLC_Report.dbo.Redeem r with (nolock)
	on r.id = t.ItemID
LEFT Outer JOIN (select ItemID as TransID from SLC_Report.dbo.trans t2 with (nolock) where t2.typeid=4) as Cancelled ON Cancelled.TransID=T.ID
inner join SLC_Report.dbo.RedeemAction as ra with (nolock) on t.ID = ra.transid and ra.Status = 1
where	t.TypeID=3 and
		T.Points > 0 and t.ProcessDate < @Today
order by TranID

Create clustered index ixc_Redemptions on #Redemptions(FanID)
------------------------------------------------------------------------------------------------------------
-----------------------------------------------------Combine------------------------------------------------
------------------------------------------------------------------------------------------------------------
--Combine the currently attended statuses together
Select	a.FanID,
		Cast(Case
				When c.CJ_Status is not null then c.CJ_Status
				When b.CJ_Status is not null then b.CJ_Status
				Else 'MOT1'
			 End as nvarchar(30)) as cj_Status
into #cj3
from #cb as a
left outer join #cj1 as b
	on a.fanid = b.fanid
Left outer join #cj2 as c
	on a.fanid = c.fanid
Order by FanID

Create Clustered Index ixc_cj3 on #cj3(FanID)

------------------------------------------------------------------------------------------------------------
-----------------------------------------------------CJ Statuses--------------------------------------------
------------------------------------------------------------------------------------------------------------
--Update statues if they have redeemed
Update #cj3
Set cj_Status = a.NewStatus
from #cj3 as c
inner join 
(Select  cj.FanID,
		Min(Case
				When r.fanid is null then cj.cj_Status
				When r.cancelled = 0 and r.redeemdate > dateadd(year,-1,cast(getdate() as date)) then 'Redeemer'
				When r.cancelled = 0 and r.redeemdate < dateadd(year,-1,cast(getdate() as date)) then 'Saver'
				Else cj.cj_Status
			End) as NewStatus
from #cj3 as cj
inner join #Redemptions as r
	on cj.fanid = r.fanid
Group by cj.FanID
) as a
	on c.fanid = a.fanid

------------------------------------------------------------------------------------------------------------
-----------------------------------------------------High Lower Spender-------------------------------------
------------------------------------------------------------------------------------------------------------

Select FanID,
		Case 
			When AnnualCashback >= 15 then CJ_Status + ' - High Value'
			when Datediff(month,ActivatedDate,@Today) >= 12 then CJ_Status + ' - Low Value'
			When Datediff(month,ActivatedDate,@Today) <= 11 and AnnualCashback >= Datediff(month,ActivatedDate,@Today)*1.25 then CJ_Status + ' - High Value'
			Else CJ_Status + ' - Low Value'
		End as CJ_Status
into #CJ_HL
From
(Select	cj.FanID,
		f.ActivatedDate,
		cj.cj_Status,
		Sum(Case
				When DateAvailable  between dateadd(day,1,dateadd(year,-1,@Today)) and @Today and
					DateAvailable >= f.ActivatedDate then Cashback
				Else 0
			End) AnnualCashback
from #cj3 as cj
inner join #Trans as T
	on cj.FanID = t.FanID
inner join #CB as f with (Nolock)
	on cj.FanID = f.FanID
Where cj.cj_Status in ('Redeemer','Saver')
Group by cj.FanID,
		f.ActivatedDate,
		cj.cj_Status
) as a
--Order by cj_Status
Create clustered index ixc_CJHL on #CJ_HL(FanID)

------------------------------------------------------------------------------------------------------------
------------------------------------------------Update Customer Journey Table-------------------------------
------------------------------------------------------------------------------------------------------------

Update #cj3
Set cj_Status = hl.cj_Status
from #cj3 as c
inner join #CJ_HL as hl
	on c.fanid = hl.FanID
Where c.cj_Status in ('Redeemer','Saver')
------------------------------------------------------------------------------------------------------------
--------------------------------------Populate CustomerJourneyStaging table---------------------------------
------------------------------------------------------------------------------------------------------------
insert Into Warehouse.Staging.CustomerJourneyStaging(FanID, CustomerJourneyStatus, [Date])
Select	FanID,
		CJ_Status as CustomerJourneyStatus,
		@Today as [Date]
From #cj3

Drop table #CB, #Trans, #CJ1, #cj2, #cj3, #Redemptions, #CJ_HL
End