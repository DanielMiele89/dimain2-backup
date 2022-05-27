


CREATE PROCEDURE [Report].[Bespoke_Monitoring]
AS
BEGIN
	
	SET NOCOUNT ON;



; with VirginOffers as (
				SELECT	iof.Item PublishedIronOfferID
					,	PartnerID PublishedPartnerID 
					,	BespokeCampaign
				FROM [WH_Virgin].[Selections].[CampaignSetup_POS] cs
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
				WHERE iof.Item != 0
				--AND cs.BespokeCampaign = 1
				AND cs.StartDate <= GETDATE()  and cs.StartDate >DATEADD(month,-6,getdate())
				GROUP BY iof.Item, cs.PartnerID, BespokeCampaign
), VirginSegments as (
				select vo.*,o.SegmentName
				from [WH_AllPublishers].[Derived].[Offer] o
				join VirginOffers vo
				on o.IronOfferID = vo.PublishedIronOfferID
),VisaOffers as (
				SELECT	iof.Item PublishedIronOfferID
					,	PartnerID PublishedPartnerID 
					,	BespokeCampaign
				FROM [WH_Visa].[Selections].[CampaignSetup_POS] cs
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
				WHERE iof.Item != 0
				--AND cs.BespokeCampaign = 1
				AND cs.StartDate <= GETDATE()  and cs.StartDate >DATEADD(month,-6,getdate())
				GROUP BY iof.Item, cs.PartnerID, BespokeCampaign
),VisaSegments as (
				select vo.*,o.SegmentName
				from [WH_AllPublishers].[Derived].[Offer] o
				join VisaOffers vo
				on o.IronOfferID = vo.PublishedIronOfferID
),MyRewardsOffers as (
				SELECT	iof.Item PublishedIronOfferID
					,	PartnerID PublishedPartnerID
					,	BespokeCampaign
				FROM [Warehouse].[Selections].[CampaignSetup_POS] cs
				CROSS APPLY [Warehouse].[dbo].[il_SplitDelimitedStringArray] (OfferID, ',') iof
				WHERE iof.Item != 0
				--AND cs.BespokeCampaign = 1
				AND cs.StartDate <= GETDATE()  and cs.StartDate >DATEADD(month,-6,getdate())
				GROUP BY iof.Item, cs.PartnerID, BespokeCampaign
),MyRewardsSegments as (
				select vo.*,o.SegmentName
				from [WH_AllPublishers].[Derived].[Offer] o
				join MyRewardsOffers vo
				on o.IronOfferID = vo.PublishedIronOfferID
), VirginTransactions as (
				select	p.PartnerName
					,	o.*
					,	pt.*
					,	ou.PostalSector
					,	ou.PostArea
					,	ou.PostCode
					,	ou.Region
					,	'Vigrin' as Publisher
				from VirginSegments o 
				LEFT JOIN [WH_Virgin].Derived.PartnerTrans pt
				on o.PublishedIronOfferID = pt.IronOfferID
				join wh_virgin.Derived.Outlet ou
				on ou.OutletID = pt.OutletID
				join [WH_Virgin].Derived.Partner p
				on p.PartnerID = o.PublishedPartnerID
), VisaTransactions as (
				select	p.PartnerName
					,	o.*
					,	pt.*
					,	ou.PostalSector
					,	ou.PostArea
					,	ou.PostCode
					,	ou.Region
					,	'Visa' as Publisher
				from VisaSegments o 
				LEFT JOIN [WH_Visa].Derived.PartnerTrans pt
				on o.PublishedIronOfferID = pt.IronOfferID
				join [WH_Visa].Derived.Outlet ou
				on ou.OutletID = pt.OutletID
				join [WH_Visa].Derived.Partner p
				on p.PartnerID = o.PublishedPartnerID
), MyRewardsTransactions as (
				select	p.PartnerName
					,	o.*
					,	pt.*
					,	ou.PostalSector
					,	ou.PostArea
					,	ou.PostCode
					,	ou.Region
					,	'MyRewards' as Publisher
				from MyRewardsSegments o 
				LEFT JOIN [Warehouse].Relational.PartnerTrans pt
				on o.PublishedIronOfferID= pt.IronOfferID
				join [Warehouse].Relational.Outlet ou
				on ou.OutletID = pt.OutletID
				join [Warehouse].Relational.Partner p
				on p.PartnerID = o.PublishedPartnerID
)
select	PartnerName
	,	PublishedIronOfferID
	,	SegmentName
	,	BespokeCampaign
	,	PublishedPartnerID
	,	FanID
	,	PartnerID
	,	OutletID
	,	IsOnline
	,	TransactionAmount
	,	TransactionDate
	,	TransactionWeekStarting
	,	TransactionMonth
	,	TransactionYear
	,	TransactionWeekStartingCampaign
	,	AffiliateCommissionAmount
	,	CommissionChargable
	,	CashbackEarned
	,	IronOfferID
	,	PostalSector
	,	PostArea
	,	PostCode
	,	Publisher
from VirginTransactions
UNION ALL
select	PartnerName
	,	PublishedIronOfferID
	,	SegmentName
	,	BespokeCampaign
	,	PublishedPartnerID
	,	FanID
	,	PartnerID
	,	OutletID
	,	IsOnline
	,	TransactionAmount
	,	TransactionDate
	,	TransactionWeekStarting
	,	TransactionMonth
	,	TransactionYear
	,	TransactionWeekStartingCampaign
	,	AffiliateCommissionAmount
	,	CommissionChargable
	,	CashbackEarned
	,	IronOfferID
	,	PostalSector
	,	PostArea
	,	PostCode
	,	Publisher
from VisaTransactions
UNION  
select	PartnerName
	,	PublishedIronOfferID
	,	SegmentName
	,	BespokeCampaign
	,	PublishedPartnerID
	,	FanID
	,	PartnerID
	,	OutletID
	,	IsOnline
	,	TransactionAmount
	,	TransactionDate
	,	TransactionWeekStarting
	,	TransactionMonth
	,	TransactionYear
	,	TransactionWeekStartingCampaign
	,	AffiliateCommissionAmount
	,	CommissionChargable
	,	CashbackEarned
	,	IronOfferID
	,	PostalSector
	,	PostArea
	,	PostCode
	,	Publisher
from MyRewardsTransactions


END
