
/*
 
    Author:        Michael Head
 
    Date:        18th February 2019
 
    Purpose:    To Run Tableau Bespoke Offers Report
 
*/

CREATE Procedure [Staging].[Tableau_0001_BespokeOffers]



As 
Begin

Set nocount on 

--------------------------------------------------------------------------------------------------------------------------------
-- Bespoke Offers Stats

/******************************************************************		
		Get all offers 
******************************************************************/
If OBJECT_ID('tempdb..#Offers') is not null DROP TABLE #Offers
select htm.ClientServicesRef, htm.IronOfferID
Into #Offers
from Relational.IronOffer io
inner join Relational.IronOffer_Campaign_HTM htm
	on htm.IronOfferID = io.IronOfferID
	and io.partnerid = htm.partnerid
inner join relational.partner P
	on p.partnerid = htm.partnerid
where io.startdate >= '2017-07-20'
Group by htm.ClientServicesRef, htm.IronOfferID



/******************************************************************		
		Get commission stats per offer 
******************************************************************/
If OBJECT_ID('tempdb..#Commission') is not null DROP TABLE #Commission
select o.IronOfferID
	, sum(pt.CashbackEarned) [Cashback]
	, sum(pt.CommissionChargable) [Commission]
Into #Commission
from #offers o
inner join Relational.PartnerTrans pt
on pt.IronOfferID = o.ironofferid
Group by o.ironofferid


/******************************************************************		
		Get Bespoke campaigns 
******************************************************************/
If OBJECT_ID('tempdb..#BespokeCampaigns') is not null DROP TABLE #BespokeCampaigns
Select PartnerID, ClientServicesRef, BespokeCampaign
into #BespokeCampaigns
from (
	Select * , ROW_NUMBER () over (partition by clientservicesref order by BespokeCampaign desc) RowNum
	from (
			SELECT als.PartnerID, als.ClientServicesRef
						,BespokeCampaign
					, als.MustBeIn_TableName1
			FROM Selections.ROCShopperSegment_PreSelection_ALS als 
			where StartDate >= '2017-07-20' 
			UNION
			SELECT als.PartnerID, als.ClientServicesRef
						,BespokeCampaign
					, als.MustBeIn_TableName1
			FROM Selections.CampaignSetup_DD als 
			where StartDate >= '2017-07-20' 
	) x
) y
where RowNum = 1 



/******************************************************************		
		Aggregate results up 
******************************************************************/
If OBJECT_ID('tempdb..#Aggregations') is not null DROP TABLE #Aggregations
Select distinct c.* 
	, htm.ClientServicesRef
	, p.PartnerName
	, p.PartnerID
	, bc.BespokeCampaign
	, bs.SectorName
	, p.AccountManager
	, io.StartDate
	--, month(io.startdate) Month
	--, YEAR(io.startdate) Year
Into #Aggregations
from #Commission c
inner join Relational.IronOffer_Campaign_HTM htm 
	on htm.IronOfferID = c.IronOfferID
inner join Relational.Partner p 
	on p.PartnerID = htm.PartnerID
inner join Relational.Brand b 
	on p.BrandID = b.BrandID
inner join Relational.BrandSector bs 
	on b.SectorID = bs.SectorID
inner join Relational.IronOffer io
	on io.IronOfferID = c.IronOfferID
Left join #BespokeCampaigns bc
	on bc.ClientServicesRef = htm.ClientServicesRef
where bc.BespokeCampaign is not NULL
order by PartnerName , IronOfferID


Select * From #Aggregations


End