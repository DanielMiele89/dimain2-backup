CREATE Procedure [Staging].[OPE_05_Assign_Slots_WoWs]
as
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'OPE_05_Assign_Slots_WoWs',
		TableSchemaName = 'Staging',
		TableName = 'OPE_Members',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'U'
------------------------------------------------------------------------
---------------------Create list of non-base offers---------------------
------------------------------------------------------------------------

if object_id('tempdb..#Offers_AB') is not null drop table #Offers_AB
Select	w.*,
		ct.ControlPercentage
Into #Offers_AB
From Staging.OPE_Offers_Weighted as w
left outer join Relational.PartnerOffers_Base as pob
	on w.IronOfferID = pob.OfferID
Left Outer join Relational.Partner_BaseOffer as pbo
	on w.IronOfferID = pbo.OfferID
left outer join Relational.Partner_NonCoreBaseOffer as nc
	on w.IronOfferID = nc.IronOfferID
left outer join Relational.IronOffer_Campaign_HTM as a
	on w.IronOfferID = a.IronOfferID
left outer join Staging.IronOffer_Campaign_Type as ct
	on a.ClientServicesRef = ct.ClientServicesRef
Where	pob.OfferID is null and
		pbo.OfferID is null and
		nc.IronOfferID is null
------------------------------------------------------------------------
-------------------- LOOK TO ADD MEMBERS TO OFFERS ---------------------
------------------------------------------------------------------------
Declare @RowNo int,@MaxRow int,@Slots int,@MailGroup int
Set @RowNo = 1
--Set @RowNo = 13
Set @MaxRow = (Select MAX(RowNumber) from #Offers_AB)
Set @Slots = 7

While @RowNo <= @MaxRow
--if	@RowNo = 13
Begin
	--**For IOM customers add slot
		Update	Staging.OPE_Members
		Set		FinalSlot = CurrentSlot,
				[Status] = 1
	
		from Staging.OPE_Members as m
		inner join #Offers_AB as o
			on	m.IronOfferID = o.IronOfferID and
				m.HTMID = o.HTMID
		Where	o.RowNumber = @RowNo and
				m.CurrentSlot <= @Slots and
				IOM = 1 and
				m.Status = 0 and
				m.FinalSlot is null
			
		Set @MailGroup = (
		--**For NIOM customers create Mail Count
		Select Ceiling((Count(*)*(0.01*(100-Coalesce(ControlPercentage,0))))) as Mail
		from Staging.OPE_Members as m
		inner join #Offers_AB as o
			on	m.IronOfferID = o.IronOfferID and
				m.HTMID = o.HTMID
		Where	o.RowNumber = @RowNo and
				m.CurrentSlot <= @Slots and
				IOM = 0 and 
				m.Status = 0 and
				m.FinalSlot is null
		Group by ControlPercentage
		)
		--**For NIOM customers create Mail and Control entries
		if object_id('tempdb..#t1') is not null drop table #t1
		Select	m.*,ROW_NUMBER() OVER(ORDER BY NewID() DESC) AS RowNo
		Into #t1	
		from Staging.OPE_Members as m
		inner join #Offers_AB as o
			on	m.IronOfferID = o.IronOfferID and
				m.HTMID = o.HTMID
		Where	o.RowNumber = @RowNo and
				m.CurrentSlot <= @Slots and
				IOM = 0 and 
				m.Status = 0
		Order by o.TotalScore
	
		Update Staging.OPE_Members
		set FinalSlot =	Case
							When t.RowNo > @MailGroup then 0
							Else m.[CurrentSlot]
						End,
			[Status] =  Case
							When t.RowNo > @MailGroup then 2
							Else 1
						End
		from Staging.OPE_Members as m
		inner join #t1 as t
			on	m.FanID = t.FanID and
				m.HTMID = t.HTMID and
				m.IronOfferID = t.IronOfferID
	
		Update Staging.OPE_Members
		Set CurrentSlot = m.CurrentSlot-1
		from Staging.OPE_Members as m
		inner join #t1 as t
			on	m.FanID = t.FanID and
				t.CurrentSlot < m.CurrentSlot
		Where t.RowNo > @MailGroup
	
	Set @RowNo = @RowNo+1
End

------------------------------------------------------------------------
------------------ Update extra offerslots to Status = 3 ---------------
------------------------------------------------------------------------

Update	Staging.OPE_Members
Set		FinalSlot = 0, 
		Status = 3
Where	FinalSlot is null and 
		CurrentSlot > 7

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'OPE_05_Assign_Slots_WoWs' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_Members' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(*) from Staging.OPE_Members)
where	StoredProcedureName = 'OPE_05_Assign_Slots_WoWs' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_Members' and
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