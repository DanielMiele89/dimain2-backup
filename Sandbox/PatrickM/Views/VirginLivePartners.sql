create view patrickm.VirginLivePartners  as
select partnerid, min(a.startdate) as startdate, max(a.enddate) as enddate, sum(vol) as offervolume from
(
SELECT ironofferid, startdate, enddate, count(*) as vol
FROM [WH_Virgin].[Segmentation].[OfferMemberAddition] --where  getdate() - startdate < 0
group by ironofferid, startdate, enddate
having count(*) >= 2000
) as a --all live offers this selection
left join [WH_Virgin].[Derived].[IronOffer] as b
	on a.ironofferid = b.ironofferid
	where b.partnerid is not NULL
group by partnerid