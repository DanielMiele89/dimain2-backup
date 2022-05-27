CREATE Procedure [Staging].[SSRS_R0060_PartnerMIDsNotInGAS_PerPartner] 
			@PartnerID int
As
Declare  @BrandID int
--Set @PartnerID = 3996
Set @BrandID = (Select BrandID from Relational.Partner where @PartnerID = PartnerID)

IF OBJECT_ID('tempdb..#partner') IS NOT NULL DROP TABLE #partner
	--Find Partner Record
	select	p.PartnerID as ID
			,p.PartnerName as name
	into	#partner
	from	Relational.Partner as p
	Where p.PartnerID = @PartnerID
	--Find Secondary Partner Record
	Union All
	select	p.PartnerID
			,p.PartnerName
	from	Relational.Partner as p
	inner Join Warehouse.[iron].[PrimaryRetailerIdentification] as a
		on p.PartnerID = a.PartnerID
	Where a.PrimaryPartnerID = @PartnerID

----------------------------------------------------------------------------
-----------------------Create List Of MIDs from GAS-------------------------
----------------------------------------------------------------------------
if object_id('tempdb..#MIDs') is not null drop table #MIDs

select OutletID,MerchantID
into #MIDs
from Relational.Outlet as o
inner join #Partner as p
	on o.PartnerID = p.ID

Insert into #MIDs
select OutletID,'0'+MerchantID as MerchantID
from Relational.Outlet as o
inner join #Partner as p
	on o.PartnerID = p.ID
Where left(MerchantID,1) like '[1-9]'

Insert into #MIDs
select OutletID,right(MerchantID,len(MerchantID)-1) as MerchantID
from Relational.Outlet as o
inner join #Partner as p
	on o.PartnerID = p.ID
Where left(MerchantID,1) like '[0]'

Create Clustered index MID_idx on #MIDs(OutletID,MerchantID)
----------------------------------------------------------------------------
--------------Find MIDs in ConsumerCombination that do not match------------
----------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
Select * 
into #t1
from Relational.ConsumerCombination as cc
left outer join #MIDs as m
	on m.MerchantID = ltrim(rtrim(cc.MID))
Where BrandID = @BrandID and m.OutletID is null

Create clustered index t1_ind on #t1(ConsumerCombinationID)

----------------------------------------------------------------------------
--------------Get stats on Trans from ConsumerTrans and Holding-------------
----------------------------------------------------------------------------
if object_id('tempdb..#Trans') is not null drop table #Trans
Create table #Trans(ConsumerCombinationID int,FirstTran Date, LastTran Date, Trans int)

Insert into #Trans
Select	t.ConsumerCombinationID,
		Min(TranDate) as FirstTran,
		Max(TranDate) as LastTran,
		Count(*) as Trans
from Warehouse.relational.ConsumerTransaction as ct  with (nolock) 
inner join #t1 as t
	on ct.ConsumerCombinationID = t.ConsumerCombinationID
Group by t.ConsumerCombinationID

Insert into #Trans
Select	t.ConsumerCombinationID,
		Min(TranDate) as FirstTran,
		Max(TranDate) as LastTran,
		Count(*) as Trans
from Warehouse.relational.ConsumerTransactionHolding as ct  with (nolock) 
inner join #t1 as t
	on ct.ConsumerCombinationID = t.ConsumerCombinationID
Group by t.ConsumerCombinationID

----------------------------------------------------------------------------
--------------Combine figures from ConsumerTrans and Holding----------------
----------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#TranCounts') IS NOT NULL DROP TABLE #TranCounts
Select	a.ConsumerCombinationID,
		a.BrandMIDID,
		a.Narrative,
		a.LocationCountry,
		mcc.MCC,
		mcc.MCCDesc,
		Min(b.FirstTran) as FirstTran,
		Max(LastTran) as LastTran,
		Sum(Trans) as Trans
Into #TranCounts
from #t1 as a
Left Outer join #Trans as b
	on a.ConsumerCombinationID = b.ConsumerCombinationID
Left join relational.MCCList as mcc
	on a.MCCID = mcc.MCCID
--Order by a.ConsumerCombinationID
Group by a.ConsumerCombinationID,a.BrandMIDID,a.Narrative,a.LocationCountry,mcc.MCC,mcc.MCCDesc

Create Clustered Index TranCount_Idx on #TranCounts (ConsumerCombinationID)

----------------------------------------------------------------------------
--------------------Get list of currentlyactive customers-------------------
----------------------------------------------------------------------------

IF OBJECT_ID ('tempdb..#AC') IS NOT NULL DROP TABLE #AC
Select c.fanid,cl.CinID,c.ActivatedDate
Into #AC
From Relational.Customer as c
inner join Relational.CINList as cl
	on c.Sourceuid = cl.cin
Where c.currentlyactive = 1

Create clustered index AC_IDX on #AC(CinID)
Create NonClustered index AC_IDX_NC on #AC(ActivatedDate)
----------------------------------------------------------------------------
-------------Find the currently active peoples transactions-----------------
----------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#ActivatedTrans') IS NOT NULL DROP TABLE #ActivatedTrans
select ct.*,ActivatedDate,FanID
Into #ActivatedTrans
from relational.consumertransaction as ct
inner join #TranCounts as tc
	on ct.ConsumerCombinationID = tc.ConsumerCombinationID
inner join #AC as ac
	on ct.CINID = ac.CinID
where TranDate >= Dateadd(Month,3,getdate()) and TranDate > ac.ActivatedDate
----------------------------------------------------------------------------
-----------------Find cashback rate for each transaction--------------------
----------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#ActivatedTrans_CB') IS NOT NULL 
			DROP TABLE #ActivatedTrans_CB
Select  ConsumerCombinationID,
		FileID,
		RowNum,
		FanID,
		TranDate,
		Amount,
		CardholderPresentData,
		Max(CashbackRate) as CashbackRate
Into #ActivatedTrans_CB
from 
(Select at.ConsumerCombinationID,
		at.FileID,
		at.RowNum,
		at.FanID,
		at.TranDate,
		at.Amount,
		at.CardholderPresentData,
		pcr.RequiredIronOfferID,
		i.StartDate, 
		i.EndDate,
		Max(pcr.CommissionRate) as cashbackrate,
		Max(pcr.requiredminimumbasketsize) as minimumbasketsize,
		max(requiredmerchantid) as RequiredMerchantID
from #ActivatedTrans as at
inner join relational.customer as c
	on at.fanid = c.fanid
inner join relational.ironoffermember as iom
	on c.compositeid = iom.compositeid
inner join relational.ironoffer as i
	on iom.ironofferid = i.ironofferid
inner join slc_report.dbo.partnercommissionrule as pcr
	on i.ironofferid = pcr.requiredironofferid 
Where	i.partnerid = @PartnerID and 
		(
			(at.TranDate between iom.StartDate and iom.EndDate or
			 at.TranDate >= iom.StartDate and iom.EndDate is null and i.EndDate >= at.TranDate)
				or

			(	iom.StartDate is null and 
				iom.EndDate is null and
				(	i.EndDate >= at.TranDate or i.EndDate is null) and 
				i.startdate <= at.TranDate
			)
		) and 
		pcr.typeid = 1 and 
		pcr.status = 1 and 
		Amount > 0
group by at.FileID,at.RowNum,at.FanID,at.TranDate,at.Amount,pcr.RequiredIronOfferID,i.StartDate, i.EndDate,at.CardholderPresentData,at.ConsumerCombinationID
) as a
Where (Amount > Minimumbasketsize or Minimumbasketsize is null) and RequiredMerchantID is null
Group by FileID,
		RowNum,
		FanID,
		TranDate,
		Amount,
		CardholderPresentData,
		ConsumerCombinationID
-------------------------------------------------------------------------------------------------------
----------------------------------------- Produce final dataset ---------------------------------------
-------------------------------------------------------------------------------------------------------
--Truncate Table Staging.Outlet_NotinMIDS

Insert into Staging.R_0060_Outlet_NotinMIDS
Select	a.ConsumerCombinationID,
		Cast(a.MID as varchar(50)) as MerchantID,
		Cast(a.Narrative as varchar(50)) as Narrative,
		Cast(a.LocationCountry as varchar(3)) as LocationCountry,
		Cast(a.MCC as varchar(4)) as MCC,
		Cast(a.MCCDesc as Varchar(200)) as MCCDesc,
		tc.FirstTran,
		tc.LastTran,
		tc.Trans,
		Sum([Offline Trans]) as [Offline Tranx], 
		Sum([Offline Cashback]) as [Offline Cashback],
		Sum([Online Trans]) as [Online Tranx],
		Sum([Online Cashback]) as [Online Cashback],
		@PartnerID as PartnerID
From
(Select	t.ConsumerCombinationID,t.MID,t.Narrative,LocationCountry,mcc.MCC,mcc.MCCDesc,
			Case
				When Act.CardholderPresentData <> 5 then 1
				Else 0
			End as [Offline Trans],
			Cast(Case
					When Act.CardholderPresentData <> 5 then Round(Act.Amount*(CashbackRate/100),2)
					Else 0
				 End as Numeric(10,2)) [Offline Cashback],
			Case
				When Act.CardholderPresentData = 5 then 1
				Else 0
			End as [Online Trans],
			Cast(Case
					When Act.CardholderPresentData = 5 then Round(Act.Amount*(CashbackRate/100),2)
					Else 0
				 End as Numeric(10,2)) [Online Cashback]
from #t1 as t
Left Outer join #ActivatedTrans_CB as Act
	on t.ConsumerCombinationID = Act.ConsumerCombinationID
Left Outer Join Relational.MCCList as mcc
	on t.MCCID = mcc.MCCID
) as a
Left outer join #TranCounts as tc
	on a.ConsumerCombinationID = tc.ConsumerCombinationID
Where LastTran >= dateadd(week,-6,Getdate()) and a.Narrative not Like 'crv*%' and a.Narrative not Like 'PayPal%' and replace(a.LocationCountry,' ','') = 'GB'
Group by a.ConsumerCombinationID,a.MID,a.Narrative,a.LocationCountry,tc.FirstTran,tc.LastTran,tc.Trans,a.MCC,a.MCCDesc

