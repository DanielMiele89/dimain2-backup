--Use Warehouse

/*
	
	Author:		Stuart Barnley

	Date:		21st July 2016

	Purpose:	To provide a list of merchants who ran offers on MyRewards
				in a date range


*/
Create Procedure Staging.SSRS_0127_MerchantsOnMyRewardBetween (@StartDate date,@EndDate date)
With Execute as owner
as
--Set @StartDate = '2016-06-01'
--Set @EndDate = '2016-06-30'
-----------------------------------------------------------------------------
------------------------Find partners with offers----------------------------
-----------------------------------------------------------------------------
if object_id('tempdb..#Partners') is not null drop table #Partners

Select Distinct p.PartnerID,
				p.PartnerName,
				Case
					When Coalesce(p.CurrentlyActive,0) = 1 then 'Yes'
					Else 'No'
				End as CurrentlyActvePartner
into #Partners
from Relational.IronOffer as i
inner join Relational.Partner as p
	on i.PartnerID = p.PartnerID
Where I.StartDate <= @EndDate and
	(	
		I.EndDate > @StartDate 
			or 
		I.EndDate is null
	) and
	i.[IsSignedOff] = 1
	and IsDefaultCollateral = 0 
	and IsAboveTheLine = 0
-----------------------------------------------------------------------------
---------------Remove Partners without valid Partner_CBP entry---------------
-----------------------------------------------------------------------------
Delete from #Partners
Where PartnerID not in (
							Select p.PartnerID
							from #Partners as p
							inner join Relational.Partner_CBPDates as cbp
								on p.partnerid = cbp.partnerid
							Where	Scheme_EndDate >= @StartDate 
										or 
									Scheme_EndDate is null
						)

Create Clustered index i_Partners_PartnerID on #Partners (PartnerID)
-----------------------------------------------------------------------------
-------------Find those partners with a base offer within period-------------
-----------------------------------------------------------------------------
if object_id('tempdb..#Core') is not null drop table #Core
Select Distinct p.PartnerID
Into #Core
from #Partners as p
inner join Relational.PartnerOffers_Base as pob
	on p.partnerid = pob.partnerid
Where StartDate <= @EndDate and
	(	
		EndDate > @StartDate 
			or 
		EndDate is null
	)

Create Clustered index i_Core_PartnerID on #Core (PartnerID)
-----------------------------------------------------------------------------
----------Find those partners with a non-core base offer within period-------
-----------------------------------------------------------------------------
if object_id('tempdb..#NonCore') is not null drop table #NonCore
Select Distinct p.PartnerID
Into #NonCore
from #Partners as p
inner join [Relational].[Partner_NonCoreBaseOffer] as po
	on p.partnerid = po.partnerid
inner join Relational.IronOffer as i
	on po.IronOfferid = i.IronOfferID
Where I.StartDate <= @EndDate and
	(	
		I.EndDate > @StartDate 
			or 
		I.EndDate is null
	)

Create Clustered index i_NonCore_PartnerID on #NonCore (PartnerID)

-----------------------------------------------------------------------------
------------Find those partners with Transactions within the period----------
-----------------------------------------------------------------------------
if object_id('tempdb..#Tranx') is not null drop table #Tranx
Select Distinct p.PartnerID
Into #Tranx
from #Partners as p
inner Join Relational.PartnerTrans as pt
	on p.PartnerID = pt.PartnerID
Where TransactionDate Between @StartDate and @EndDate

Create Clustered index i_Tranx_PartnerID on #Tranx (PartnerID)

-----------------------------------------------------------------------------
-----------------------------------Corrolate Data----------------------------
-----------------------------------------------------------------------------
Select	p.PartnerID,
		p.PartnerName,
		p.CurrentlyActvePartner,
		Case
			When c.PartnerID is not null then 'Yes'
			Else 'No'
		End as Core_In_Period,
		Case
			When nc.PartnerID is not null then 'Yes'
			Else 'No'
		End as NonCore_In_Period,
		Case
			When t.PartnerID is not null then 'Yes'
			Else 'No'
		End as Tranx_In_Period
From #Partners as p
Left Outer join #Core as c
	on p.partnerid = c.partnerid
Left Outer join #NonCore as nc
	on p.PartnerID = nc.partnerid
left outer join #Tranx as t
	on p.PartnerID = t.PartnerID
