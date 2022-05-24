

CREATE procedure [Staging].[SSRS_R0144__nFI_Partner_Deals_PotentialMissingRecords]

as 
begin

-- ************************************************************************************************************************************

-- Author:			Zoe Taylor

-- Create date:		2017-01-06

-- Description:		Used to create a results set for R_0144 to detect potential missing rows in the Relational.nFI_Partner_Deals table

-- ************************************************************************************************************************************

-- Get all possible combinations of clubs and partners that have an offer already started or finished
IF Object_id('tempdb..#t1') IS NOT NULL  DROP TABLE #t1 
select distinct n_io.PartnerID, n_io.ClubID, n_io.ID,n_io.StartDate, IsAppliedToAllMembers
into #t1
from nFI.Relational.IronOffer n_io
left join Warehouse.Relational.nFI_Partner_Deals w_pd
	on w_pd.PartnerID = n_io.PartnerID and w_pd.ClubID = n_io.ClubID
where n_io.IsSignedOff = 1
and n_io.StartDate < getdate()
 and (w_pd.ClubID is null and w_pd.PartnerID is null)
 
create clustered index i_1 on #t1 (PartnerID, ClubID, ID)


-- Find those offers that have memberships (therefore were live to someone)
IF Object_id('tempdb..#Memberships') IS NOT NULL  DROP TABLE #Memberships 
Select t.*
into #Memberships
from #t1 as t
Left Outer join nfi.relational.ironoffermember as iom
	on t.ID = iom.IronOfferID
Where iom.FanID is not null or t.IsAppliedToAllMembers = 1
Group by t.PartnerID,t.ClubID,t.id,t.StartDate,IsAppliedToAllMembers


---- Select only those that have incentivised transactions against the offers
IF Object_id('tempdb..#trans') IS NOT NULL  DROP TABLE #trans
select distinct t.partnerid, t.ClubID, t.ID,Min(TransactionDate) as FirstTrans
into #trans
from #Memberships t
inner join nfi.Relational.PartnerTrans pt
	on pt.IronOfferID = t.ID
Group by t.partnerid, t.ClubID, t.ID


-- Get the partner name and club name of those that have incentivesed transactions against the offers
IF Object_id('tempdb..#NewPotentialDeals') IS NOT NULL  DROP TABLE #NewPotentialDeals
Select	ClubID,
		ClubName,
		a.PartnerName,
		a.PartnerID,
		BrandID as BrandID,
		BrandName as BrandName, 
		Case
			When ClubID = 12 then 'TBC'
			Else 'Reward'
		End as IntroducedBy, 
		Case
			When ClubID = 12 then 'TBC'
			Else 'Reward'
		End  as Managed_by,
		1 as Current_Deal,
		StartDate as StartDate,
		NULL as EndDate,
		--CommissionRate, 
		Round(Cast(100 as real)/CommissionRate,2,0) as CashbackRate
Into #NewPotentialDeals
from (
select p.PartnerID, p.PartnerName, c.ClubID, c.ClubName,
		Max(Case 
				When pcr.typeid = 1 then pcr.CommissionRate 
				Else 0
			End) as CashbackRate,
		Max(Case 
				When pcr.typeid = 2 then pcr.CommissionRate 
				Else 0
			End) as Commission,
		Max(Case 
				When pcr.typeid = 2 then pcr.CommissionRate 
				Else 0
			End) /
		Max(Case 
				When pcr.typeid = 1 then pcr.CommissionRate 
				Else 0
			End) as CommissionRate,
		Min(t.StartDate) as StartDate
from #Memberships t
inner join nfi.Relational.Partner p
	on p.PartnerID = t.PartnerID
inner join nfi.Relational.club c
	on c.ClubID = t.ClubID
inner join nfi.Relational.IronOffer_PartnerCommissionRule pcr
	on pcr.IronOfferID = t.ID
where pcr.DeletionDate is null
and pcr.status = 1
Group by p.PartnerID, p.PartnerName, c.ClubID, c.ClubName
) as a
Left Outer Join warehouse.relational.partner as p2
	on a.PartnerID = p2.PartnerID
--order by t.PartnerID, t.ClubID, t.ID, pcr.CommissionRate	


-- Updates test offer start dates to the launch date
Update a
Set StartDate = b.StartDate
from #NewPotentialDeals as a
inner join Staging.nFI_Partner_Deals_Publisher_Launches as b
	on a.ClubID = b.clubid
Where b.StartDate > a.StartDate


-- sets the startdate of any offers that received transactions to the minimum transaction date
Update a
Set StartDate = b.FirstTrans
from #NewPotentialDeals as a
inner join #trans as b
	on	a.ClubID = b.clubid and
		a.PartnerID = b.partnerid
Where b.FirstTrans < a.StartDate


-- Updates the brandid and brand name where we have a primary retailer
Update b
Set BrandId = p.BrandID,
	BrandName = p.BrandName
From #NewPotentialDeals as b
inner join Warehouse.iron.PrimaryRetailerIdentification as a
	on b.partnerid = a.PartnerID
inner join warehouse.relational.partner as p
	on a.PrimaryPartnerID = p.PartnerID
Where b.BrandID is null


-- Updates the brandid and brand name where we have a primary retailer
Update b
Set BrandId = p.BrandID,
	BrandName = p.BrandName
From #NewPotentialDeals as b
inner join Warehouse.iron.PrimaryRetailerIdentification as a
	on b.partnerid = a.PrimaryPartnerID
inner join warehouse.relational.partner as p
	on a.PartnerID = p.PartnerID
Where b.BrandID is null


-- Calculates the Reward percentage and the Publisher percentage commission and displays the final results set
select	a.*, 
		round((1 - (CashbackRate/100)) * Reward, 2, 0) as Reward,
		round((1 - (CashbackRate/100)) * Publisher, 2, 0) as Publisher
from #NewPotentialDeals a
left join Staging.nFI_Partner_Deals_Publisher_Rates b
	on a.ClubID = b.ClubID

end