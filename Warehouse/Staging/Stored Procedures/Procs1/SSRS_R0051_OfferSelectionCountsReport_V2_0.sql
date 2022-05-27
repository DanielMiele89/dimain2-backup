
create procedure [Staging].[SSRS_R0051_OfferSelectionCountsReport_V2_0] @StartDate date

as begin


if object_id('tempdb..#OfferCounts') is not null drop table #OfferCounts
Select io.IronOfferID,Count(*) as Customers,TopCashBackRate
Into #OfferCounts
From relational.IronOffer as io with (nolock)
inner join warehouse.iron.OfferMemberAddition as a with (nolock)
	on io.IronOfferID = a.IronOfferID
Where (io.enddate is null or io.enddate >= getdate()) and a.StartDate = @StartDate
Group by io.IronOfferID,TopCashBackRate

Create Clustered index I_OfferCounts_IronOfferID on #offercounts (IronOfferID)

Select p.PartnerName,ClientServicesRef,oc.IronOfferID, CashbackRate, Customers
From #OfferCounts as oc
inner join relational.IronOffer_Campaign_HTM as a
	on oc.IronOfferID = a.IronOfferID
inner join relational.partner as p
	on a.PartnerID = p.PartnerID

end
