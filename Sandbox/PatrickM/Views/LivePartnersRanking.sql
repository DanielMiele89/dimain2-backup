create view patrickm.LivePartnersRanking as 
select 'Virgin CC' as Publisher,
		partnerid, 
		partnername, 
		max(startdate) as startdate,
		max(enddate) as enddate,
		count(*) as [Trans Vol in last 3 months],
		count(distinct CINID) as [Customer Vol in last 3 months],
		sum(amount) as [Trans Val in last 3 months],
		max(offervolume) as [Volume of Customers on Offer],
		RANK() OVER (Order BY COUNT(*) DESC) as ranking

from
(
SELECT [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
	  , max(offervolume) as offervolume
  FROM sandbox.patrickm.VirginLivePartners as p
  left join [WH_Virgin].[Derived].[Partner] as a
	on p.partnerid = a.partnerid
  left join  [WH_Virgin].[Trans].[ConsumerCombination] as b 
	on a.brandid = b.brandid
group by [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
) as a
left join [WH_Virgin].[Trans].[ConsumerTransaction] as b
	on a.consumercombinationid = b.consumercombinationid
where b.trandate >= cast(DATEADD(Month, -3, getdate()) as date)
group by brandid, partnerid,
		partnername

union

select 'Virgin PCA' as Publisher,
		partnerid, 
		partnername, 
		max(startdate) as startdate,
		max(enddate) as enddate,
		count(*) as [Trans Vol in last 3 months], 
		count(distinct CINID) as [Customer Vol in last 3 months],
		sum(amount) as [Trans Val in last 3 months],
		max(offervolume) as [Volume of Customers on Offer],
		RANK() OVER (Order BY COUNT(*) DESC) as ranking

from
(
SELECT [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
	  , max(offervolume) as offervolume
  FROM 	sandbox.patrickm.VirginPCALivePartners as p
  left join [WH_Virgin].[Derived].[Partner] as a
	on p.partnerid = a.partnerid
  left join  [WH_Virgin].[Trans].[ConsumerCombination] as b 
	on a.brandid = b.brandid
group by [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
) as a
left join [WH_Virgin].[Trans].[ConsumerTransaction] as b
	on a.consumercombinationid = b.consumercombinationid
where b.trandate >= cast(DATEADD(Month, -3, getdate()) as date)
group by brandid, partnerid,
		partnername

union

select 'Barclaycard' as Publisher,
		partnerid, 
		partnername, 
		max(startdate) as startdate,
		max(enddate) as enddate,
		count(*) as [Trans Vol in last 3 months], 
		count(distinct CINID) as [Customer Vol in last 3 months],
		sum(amount) as [Trans Val in last 3 months],
		max(offervolume) as [Volume of Customers on Offer],
		RANK() OVER (Order BY COUNT(*) DESC) as ranking
 from
(
SELECT [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
	  , max(offervolume) as offervolume
  FROM sandbox.patrickm.VISABarclaycardLivePartners as p
  left join WH_Visa.[Derived].[Partner] as a
	on p.partnerid = a.partnerid
  left join  WH_Visa.[Trans].[ConsumerCombination] as b 
	on a.brandid = b.brandid
group by [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
) as a
left join WH_Visa.[Trans].[ConsumerTransaction] as b
	on a.consumercombinationid = b.consumercombinationid
where b.trandate >= cast(DATEADD(Month, -3, getdate()) as date)
group by brandid, partnerid,
		partnername

union

select 'Natwest' as Publisher,
		partnerid, 
		partnername, 
		max(startdate) as startdate,
		max(enddate) as enddate,
		count(*) as [Trans Vol in last 3 months], 
		count(distinct CINID) as [Customer Vol in last 3 months], 
		sum(amount) as [Trans Val in last 3 months],
		max(offervolume) as [Volume of Customers on Offer],
		RANK() OVER (Order BY COUNT(*) DESC) as ranking

 from
(
SELECT [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid
	  , max(offervolume) as offervolume
FROM sandbox.patrickm.NWBLivePartners as p
  left join Warehouse.Relational.[Partner] as a
	on p.partnerid = a.partnerid
  left join  Warehouse.Relational.[ConsumerCombination] as b 
	on a.brandid = b.brandid
group by [ConsumerCombinationID]
      ,b.[BrandID]
	  , a.partnername
	  , p.startdate
	  , p.enddate
	  , p.partnerid 
) as a
left join Warehouse.Relational.[ConsumerTransaction_MyRewards] as b
	on a.consumercombinationid = b.consumercombinationid
where b.trandate >= cast(DATEADD(Month, -3, getdate()) as date)
group by brandid, partnerid, partnername
