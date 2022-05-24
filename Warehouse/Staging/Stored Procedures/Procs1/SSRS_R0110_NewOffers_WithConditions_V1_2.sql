/*
	Author:			Stuart Barnley
	Date:			03-12-2015

	Description:	This stored procedure is used to populate the report R_0110.

					This pulls off the data related to new offers so they
					can be passed on for checking.

	Update:			
					
*/
CREATE Procedure [Staging].[SSRS_R0110_NewOffers_WithConditions_V1_2]
				 @StartDate Date, @EndDate Date, @ClubID int
as
----------------------------------------------------------------------
-----------------------List of Non Basic Offers-----------------------
----------------------------------------------------------------------
--Offers with Minimum Spend or MID related rules
if object_id('tempdb..#BasicOffers') is not null drop table #BasicOffers
Select DISTINCT I.ID as IronOfferID
Into #BasicOffers
from SLC_Report..IronOffer as i
inner join SLC_Report.dbo.PartnerCommissionRule as pcr
	on i.ID = pcr.RequiredIronOfferID
Where	Status = 1 AND 
		(	pcr.RequiredMinimumBasketSize is not null or 
			pcr.RequiredMerchantID is not null or 
			pcr.RequiredChannel is not null
		) and
		Cast(i.StartDate as Date) Between @StartDate and @EndDate
----------------------------------------------------------------------
----------------Pull off a list of offers and rates-------------------
----------------------------------------------------------------------
if object_id('tempdb..#Offers') is not null drop table #Offers
Select I.ID as IronOfferID, 
		I.Name as IronOfferName,
		i.StartDate,
		i.EndDate,
		Datediff(day,i.StartDate,i.EndDate)+1  as OfferPeriod,
		I.PartnerID,
		P.Name as PartnerName,
		Max(Case
				When pcr.TypeID = 1 and pcr.Status = 1 then pcr.CommissionRate
				Else NULL
			End) as CashbackRate,
		Max(Case
				When pcr.TypeID = 2 and pcr.Status = 1 then pcr.CommissionRate
				Else NULL
			End) as CommissionRate,
		ioc.ClubID,
		i.IsSignedOff,
		IsAppliedToAllMembers,
		pcr.RequiredMinimumBasketSize,
		pcr.RequiredMerchantID,
		pcr.RequiredChannel
Into #Offers
from SLC_Report..ironoffer as I
inner join SLC_Report.dbo.PartnerCommissionRule as pcr
	on	i.ID = pcr.RequiredIronOfferID
inner join SLC_report..partner as p
	on	i.PartnerID = P.ID
inner join slc_report.dbo.IronOfferClub as ioc
	on i.ID = ioc.IronOfferID
inner join #BasicOffers as bo
	on i.ID = bo.IronOfferID
Where	Cast(i.StartDate as Date) Between @StartDate and @EndDate and
		ioc.ClubID in (@ClubID) and
		pcr.Status = 1 and
		pcr.Deletiondate is null
Group by I.ID,I.Name,i.StartDate,i.EndDate,I.PartnerID,P.Name,ioc.ClubID,
		 i.IsSignedOff,i.IsAppliedToAllMembers,pcr.RequiredMinimumBasketSize,
		 pcr.RequiredMerchantID,pcr.RequiredChannel
----------------------------------------------------------------------
-----------------------------Display Offers---------------------------
----------------------------------------------------------------------
Select * from #Offers
