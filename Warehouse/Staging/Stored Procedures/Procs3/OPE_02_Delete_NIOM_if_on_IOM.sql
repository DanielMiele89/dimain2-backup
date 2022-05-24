CREATE Procedure [Staging].[OPE_02_Delete_NIOM_if_on_IOM]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'OPE_02_Delete_NIOM_if_on_IOM',
		TableSchemaName = 'Staging',
		TableName = 'NominatedOfferMember_Prospects',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'D'
		
Declare @Rows int

Set @Rows = (Select COUNT(*) from Staging.NominatedOfferMember_Prospects)

------------------------------------------------------------------------------------------------------------------
--------------------Create List of customers who are selected for an offer when on one in IOM---------------------
------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#t1') is not null drop table #t1
Select Distinct	a.CompositeID,
				a.IronOfferID
Into #t1
from
(	select	n.CompositeID,
			PartnerID,
			StartDate,
			n.IronOfferID
	from Staging.NominatedOfferMember_Prospects as n
	inner join Relational.IronOffer as i
		on n.IronOfferID = i.IronOfferID
) as a
inner join [Relational].[OPE_IronOfferMember_TEST]	as iom
	on a.CompositeID = iom.CompositeID
inner join Relational.IronOffer as i
	on	iom.IronOfferID = i.IronOfferID and
		a.PartnerID = i.PartnerID and
		a.StartDate Between i.StartDate and i.EndDate
Left Outer Join Relational.PartnerOffers_Base as pob
	on i.IronOfferID = pob.OfferID
Left Outer Join Relational.Partner_BaseOffer as pbo
	on i.IronOfferID = pbo.OfferID
left outer join Relational.Partner_NonCoreBaseOffer as nc
	on i.IronOfferID = nc.IronOfferID
Where	pob.OfferID is null and
		pbo.OfferID is null and
		nc.IronOfferID is null
------------------------------------------------------------------------------------------------------------------
----------------------------------------Delete Entries from nominated List----------------------------------------
------------------------------------------------------------------------------------------------------------------

Delete 
from Staging.NominatedOfferMember_Prospects
From Staging.NominatedOfferMember_Prospects as p
inner join #t1 as t
	on	p.CompositeID = t.CompositeID and
		p.IronOfferID = t.IronOfferID
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'OPE_02_Delete_NIOM_if_on_IOM' and
		TableSchemaName = 'Staging' and
		TableName = 'NominatedOfferMember_Prospects' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = @Rows - (Select COUNT(*) from Staging.NominatedOfferMember_Prospects)
where	StoredProcedureName = 'OPE_02_Delete_NIOM_if_on_IOM' and
		TableSchemaName = 'Staging' and
		TableName = 'NominatedOfferMember_Prospects' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
------------------------------------------Add entry in JobLog Table --------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
------------------------------------------Truncate JobLog temporary Table --------------------------
----------------------------------------------------------------------------------------------------*/
Truncate Table staging.JobLog_Temp