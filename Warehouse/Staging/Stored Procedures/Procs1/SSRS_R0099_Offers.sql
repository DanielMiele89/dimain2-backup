/*
	Author:			Stuart Barnley

	Date:			10th Sepetmber 2015

	Purpose:		To provide data to report R_0099, this SP gives info about:
	
						a. the IronOffer record
						b. the IronOfferMember record
						c. the PartnerCommissionRules table
						d. the IronOfferClub records
						e. checks the:
							i. relational.PartnerOffers_Base
							ii. relational.Partner_NonCoreBaseOffer 

*/

CREATE Procedure Staging.SSRS_R0099_Offers (@PartnerID int)
AS
Declare @PID int

Set @PID = @PartnerID

----------------------------------------------------------------------------------
-------------Assess Warehouse for the presence of a IronOffer Records-------------
----------------------------------------------------------------------------------
Select 'IronOffers' as [Type],
	   a.PartnerID,
	   a.PartnerName,
	   a.IronOfferID,
	   a.IronOfferName,
	   a.StartDate,
	   a.EndDate,
	   a.CashbackRate_Max,
	   a.CommissionRate_Max,
	   Cast(a.CommissionRate_Max/a.CashbackRate_Max as Real) as CommissionPct,
	   a.NatWest+' ' +a.RBS as Banks,
	   Count(Distinct Compositeid) as Customers
Into #Offers
From
(
select	p.PartnerID,
		p.PartnerName,
		i.ID as IronOfferID,
		i.Name as IronOfferName,
		i.StartDate,
		i.EndDate,
		Max(Case
				When pcr.TypeID = 1 then pcr.CommissionRate
				Else NULL
			End) as CashbackRate_Max,
		Max(Case
				When pcr.TypeID = 2 then pcr.CommissionRate
				Else NULL
			End) as CommissionRate_Max,
		Max(Case
				When c.ClubID = 132 then 'NatWest'
				Else ''
			End) as NatWest,
		Max(Case
				When c.ClubID = 138 then 'RBS'
				Else ''
			End) as RBS
from warehouse.relational.partner as p
inner join SLC_Report.dbo.IronOffer as i
	on p.PartnerID = i.PartnerID
left outer join slc_report.dbo.PartnerCommissionRule as pcr
	on i.ID = pcr.RequiredIronOfferID and
		pcr.Status = 1
left outer join slc_report.dbo.IronOfferClub as c
	on i.ID = c.IronOfferID
Where	p.PartnerID = @PartnerID
		
Group by p.PartnerID,p.PartnerName,i.ID,i.Name,i.StartDate,	i.EndDate
) as a
left outer join slc_report.dbo.IronOfferMember as iom
	on a.IronOfferID = iom.IronOfferID
Group by a.PartnerID,a.PartnerName,a.IronOfferID,a.IronOfferName,a.StartDate,a.EndDate,a.CashbackRate_Max,a.CommissionRate_Max,a.NatWest+' ' +a.RBS
Order by IronOfferID

Select Distinct o.*,
		pbo.StartDate as PBO_StartDate,
		pbo.EndDate as PBO_EndDate,
		pbo.CardType as PBO_CardType,
		ncbo.StartDate as ncbo_StartDate,
		ncbo.EndDate as ncbo_EndDate
from #offers as o
Left Outer join Warehouse.relational.PartnerOffers_Base as pbo
	on o.IronOfferID = pbo.OfferID
Left Outer join Warehouse.relational.Partner_NonCoreBaseOffer as ncbo
	on o.IronOfferID = ncbo.IronOfferID