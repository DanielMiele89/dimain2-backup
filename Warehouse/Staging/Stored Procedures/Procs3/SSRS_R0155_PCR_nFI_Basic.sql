/*
	Author:			Stuart Barnley
	Date:			03-12-2015

	Description:	This stored procedure is used to populate the report R_0110.

					This pulls off the data related to new offers so they
					can be passed on for checking.

	Update:			
					
*/
CREATE PROCEDURE [Staging].[SSRS_R0155_PCR_nFI_Basic]
AS
	BEGIN

	SET NOCOUNT ON

		----------------------------------------------------------------------
		-----------------------List of Non Basic Offers-----------------------
		----------------------------------------------------------------------
		--Offers with Minimum Spend or MID related rules
		if object_id('tempdb..#BasicOffers') is not null drop table #BasicOffers
		Select DISTINCT I.ID as IronOfferID
		Into #BasicOffers
		from SLC_REPL..IronOffer as i
		inner join SLC_REPL.dbo.PartnerCommissionRule as pcr
			on i.ID = pcr.RequiredIronOfferID
		Where	Status = 1 AND 
				(	pcr.RequiredMinimumBasketSize is not null or 
					pcr.RequiredMerchantID is not null or 
					pcr.RequiredChannel is not null
				)

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
						When pcr.TypeID = 1 and pcr.Status = 1 then COALESCE(pcr.CommissionAmount, pcr.CommissionRate)
						Else NULL
					End) as CashbackRate,
				Max(Case
						When pcr.TypeID = 2 and pcr.Status = 1 then COALESCE(pcr.CommissionAmount, pcr.CommissionRate)
						Else NULL
					End) as CommissionRate,
				ioc.ClubID,
				i.IsSignedOff,
				IsAppliedToAllMembers,
				pcr.RequiredChannel
		Into #Offers
		from SLC_REPL..ironoffer as I
		inner join SLC_REPL.dbo.PartnerCommissionRule as pcr
			on	i.ID = pcr.RequiredIronOfferID
		inner join SLC_REPL..partner as p
			on	i.PartnerID = P.ID
		inner join SLC_REPL.dbo.IronOfferClub as ioc
			on i.ID = ioc.IronOfferID
		left outer join #BasicOffers as bo
			on i.ID = bo.IronOfferID
		Where ioc.ClubID NOT IN (132, 138) and
				bo.IronOfferID is null and
				pcr.Status = 1 and
				pcr.Deletiondate is null
		Group by I.ID,I.Name,i.StartDate,i.EndDate,I.PartnerID,P.Name,ioc.ClubID,
				 i.IsSignedOff,i.IsAppliedToAllMembers, pcr.RequiredChannel
		----------------------------------------------------------------------
		-----------------------------Display Offers---------------------------
		----------------------------------------------------------------------
		if object_id('tempdb..#CalculatedRate') is not null drop table #CalculatedRate
		Select x.*
			, case 
				when p.FixedOverride = 1 then
					 x.cashbackrate + p.Override
				when p.FixedOverride = 0 THEN	
					(p.Override * x.CashbackRate) + x.CashbackRate
			else 0
			End as [CalculatedRate]
			, p.FixedOverride
			, p.Override
		Into #CalculatedRate
		From #Offers x
		Left Join Warehouse.apw.PartnerAlternate pa
			on pa.PartnerID = x.partnerid
		left Join Warehouse.Relational.nFI_Partner_Deals p
			on p.ClubID = x.ClubID
			and p.partnerid = coalesce(pa.AlternatePartnerID, x.partnerid)
			and p.EndDate is null

			select *
			From #CalculatedRate

	END