

CREATE procedure [Staging].[TrackableRetailersUpdate]

as 
begin


/********************************************************************************************
** Name: Staging.TrackableRetailersUpdate
** Desc: Updates the Trackable Retailers table with their acquirer and matcher, and deletes duplicated with no PartnerID
** Auth: Zoe Taylor
** Date: 24 Jan 2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1    
*********************************************************************************************/


-- Selects rows that are missing from SLC_Report and adds them to a temporary table 
IF Object_id('tempdb..#NewRows') IS NOT NULL  DROP TABLE #NewRows 
select distinct SLC_p.ID,
				slc_p.Name as PartnerName, 
				slc_tv.Name as Matcher,
				slc_p.matcher as MatcherID,
				Case
					When slc_p.Matcher = 10 then 1
					When slc_p.Matcher = 11 then 1
					When slc_p.Matcher = 12 then 3
					When slc_p.Matcher = 32 then 5
					Else 0
				End as Acquirer
Into #NewRows
from nfi.Relational.Partner nfi_p
inner join SLC_Report.dbo.Partner slc_p
	on slc_p.id = nfi_p.PartnerID
inner join SLC_Report.dbo.TransactionVector slc_tv
	on slc_tv.ID = slc_p.Matcher
inner join nfi.Relational.IronOffer nfi_io
	on nfi_io.PartnerID = nfi_p.PartnerID
left join Warehouse.Staging.TrackableRetailers w_tr
	on w_tr.PartnerID = nfi_p.PartnerID
where 1=1
and nfi_io.IsSignedOff = 1
and (nfi_io.EndDate is null or nfi_io.EndDate > getdate())
and w_tr.PartnerID is null
and (slc_p.Matcher between 10 and 12 or slc_p.Matcher = 32)
order by 1


-- Inserts rows from the temp table in to trackable retailers table
insert into Warehouse.Staging.TrackableRetailers
select tr.BrandID, n.ID [PartnerID], n.PartnerName, n.Acquirer, case when n.Acquirer = 5 then 'No' else 'Yes' end [Trackable]  from #NewRows n
inner join Warehouse.mi.PartnerBrand tr
	on tr.PartnerID = n.ID
left outer join Warehouse.Staging.TrackableRetailers a
	on tr.BrandID = a.BrandID
where a.BrandID is null


-- Looks for duplicate BrandID's and adds the ID to a temp table
IF Object_id('tempdb..#Deletions') IS NOT NULL  DROP TABLE #Deletions
select brandid, count(*) [Count]
into #Deletions
from Warehouse.Staging.TrackableRetailers tr
group by BrandID
having count(BrandID) >= 2


-- Deletes dupe values from Trackable Retailers where the BrandID exists in the temp table and the PartnerID is null, leaving the correct row in the table
delete from Warehouse.Staging.TrackableRetailers
where PartnerID is null
and brandid in (
				select BrandID from #Deletions
				)


END
