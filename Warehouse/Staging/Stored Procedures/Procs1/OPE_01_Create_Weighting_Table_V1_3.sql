--Use Warehouse_Dev
CREATE Procedure [Staging].[OPE_01_Create_Weighting_Table_V1_3] (@EmailSendDate date)
as
--Declare @EmailSendDate date
--set @EmailSendDate = 'Oct 02, 2014'
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'OPE_01_Create_Weighting_Table',
		TableSchemaName = 'Staging',
		TableName = 'OPE_Offers_Weighted',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'


------------------------------------------------------------------------------------------------------------------
---------------------------------------Create List of different HTMIDs--------------------------------------------
------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#HTMIDs') is not null drop table #HTMIDs
Select *
into #HTMIDs
From
(
Select HTMID
from Relational.HeadroomTargetingModel_Groups as g
Where HTMID >= 10
Union All
Select 0 as HTMID
) as a

------------------------------------------------------------------------------------------------------------------
---------------------------------------Create Offer Tables--------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
if object_id('Staging.OPE_Offers') is not null drop table Staging.OPE_Offers
--Truncate Table Staging.OPE_Offers
--Insert into Staging.OPE_Offers
Select	I.IronOfferID,
		I.PartnerID,
		Cast(I.StartDate as DATE) as StartDate,
		Cast(I.EndDate as DATE) as EndDate,
		HTM.HTMID,
		tbs.BaseOffer
into Staging.OPE_Offers		
from	Relational.IronOffer as i
Inner join Staging.OPE_Offers_TobeScored as tbs
		on i.IronOfferID = tbs.IronOfferID,
		#HTMIDS as HTM
Where	i.StartDate <= @EmailSendDate and
		(i.EndDate is null or i.EndDate >= @EmailSendDate)

Create Clustered Index idx_OPE_Offers_OfferAndHTM on Staging.OPE_Offers (IronOfferID,HTMID)

Create NonClustered Index idx_OPE_Offers_PartnerID on Staging.OPE_Offers (PartnerID)

Drop table #HTMIDs
------------------------------------------------------------------------------------------------------------------
-------------------------------------------Untick base for Forced In Top Base-------------------------------------
------------------------------------------------------------------------------------------------------------------
Update Staging.OPE_Offers
Set BaseOffer = 0
From Staging.OPE_Offers as o
inner join Staging.OPE_Offers_Forced as f
	on	o.IronOfferID = f.OfferID and
		(f.HTMID is null or f.HTMID = o.HTMID)
Where	f.EmailDate = @EmailSendDate and
		f.ForcedInTop = 1 and
		o.BaseOffer = 1
------------------------------------------------------------------------------------------------------------------	
------------------------------------Create list of fields to be queried-------------------------------------------
------------------------------------------------------------------------------------------------------------------
Declare @Fields nvarchar(1000)
Set @Fields = (
  Select '
		'+Field as 'text()'
	From
	(select	Case
			When t.name = 'OPE_Concept_Partner_Scores'	then 'Max(a.['+c.name+']) as '+c.name+','
			When t.name = 'OPE_Concept_Offer_Scores'	then 'Max(b.['+c.name+']) as '+c.name+','
			When t.name = 'OPE_Concept_OfferSoW_Scores' then 'Max(c.['+c.name+']) as '+c.name+','
			Else ''
		End as Field
	from sys.tables as t
	inner join sys.schemas as s
		on t.schema_id = s.schema_id
	INNER JOIN SYS.columns AS c
		on t.object_id = c.object_id
	Where	s.name = 'Staging' AND
			T.name IN ('OPE_Concept_Partner_Scores','OPE_Concept_Offer_Scores','OPE_Concept_OfferSoW_Scores') and
			c.name not in ('IronOfferID','HTMID','PartnerID')
	) as a	
 for xml path(''))		

Set  @Fields = Replace(@Fields,'&#x0D;','')
Set  @Fields = Left(@Fields,LEN(@Fields)-1)

--Select @Fields
------------------------------------------------------------------------------------------------------------------	
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
Declare @Joins nvarchar(1000),@TotalScore nvarchar(1000),@TotalScoreBase nvarchar(1000),@Qry nvarchar(max)
Set @Joins = (
  Select '
		'+Joins as 'text()'
	From
	
(
Select	Distinct
		Case
			When t.name = 'OPE_Concept_Partner_Scores'	then 'left outer join '+s.name+'.['+t.name+'] as a on oo.PartnerID = a.PartnerID
'
			When t.name = 'OPE_Concept_Offer_Scores'	then 'left outer join '+ s.name+'.['+t.name+'] as b on oo.IronOfferID = b.IronOfferID
'
			When t.name = 'OPE_Concept_OfferSoW_Scores' then 'left outer join '+ s.name+'.['+t.name+'] as c on oo.IronOfferID = c.IronOfferID and oo.HTMID = c.HTMID 
'
			Else ''
		End Joins
from sys.tables as t
inner join sys.schemas as s
	on t.schema_id = s.schema_id
INNER JOIN SYS.columns AS c
	on t.object_id = c.object_id
Where	s.name = 'Staging' AND
		T.name IN ('OPE_Concept_Partner_Scores','OPE_Concept_Offer_Scores','OPE_Concept_OfferSoW_Scores')
) as a
for xml path(''))		

Set  @Joins = Replace(@Joins,'&#x0D;','')

Set  @Joins = Left(@Joins,LEN(@Joins)-1)

------------------------------------------------------------------------------------------------------------------	
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
Set @TotalScore = (
Select Fields as 'text()'
	From
	(Select '(['+c.ConceptName+']*'+cast(Weighting as varchar)+')+' as Fields
	 from Staging.OPE_Weighting as W
	 inner join Staging.OPE_Concept as c
		on w.ConceptID = c.ConceptID
	 Where W.ConceptLevelID = 1 and c.ConceptTypeID > 1
	) as Fields
for xml path('')
)
Set  @TotalScore = Replace(@TotalScore,'&#x0D;','')
Set  @TotalScore = Left(@TotalScore,LEN(@TotalScore)-1)
--Select @TotalScore
------------------------------------------------------------------------------------------------------------------	
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
Set @TotalScoreBase = (
Select Fields as 'text()'
	From
	(Select '(['+c.ConceptName+']*'+cast(Weighting as varchar)+')+' as Fields
	 from Staging.OPE_Weighting as W
	 inner join Staging.OPE_Concept as c
		on w.ConceptID = c.ConceptID
	 Where W.ConceptLevelID = 2 and c.ConceptTypeID > 1
	) as Fields
for xml path('')
)
Set  @TotalScoreBase = Replace(@TotalScoreBase,'&#x0D;','')
Set  @TotalScoreBase = Left(@TotalScoreBase,LEN(@TotalScoreBase)-1)
--Select @TotalScore

------------------------------------------------------------------------------------------------------------------	
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
if object_id('Staging.OPE_Offers_Weighted') is not null drop table Staging.OPE_Offers_Weighted
Set @Qry ='
Select	a.*,
		Coalesce([Forced],
					Case
						When [Forced] is not null then [Forced]
						When [BaseOffer] = 0 then '+@TotalScore+'
						Else '+@TotalScoreBase+'
					End) as TotalScore,
		ROW_NUMBER() OVER (Order By Coalesce([Forced],
								Case
									When [Forced] is not null then [Forced]
									When [BaseOffer] = 0 then '+@TotalScore+'
									Else '+@TotalScoreBase+'
								End) Desc) AS RowNumber
Into Staging.OPE_Offers_Weighted
From
(Select	oo.IronOfferID,
		oo.PartnerID,
		oo.HTMID,
	   '+@Fields+',
	    Case
			When oof.OfferID is not null then 15000+oof.Score
			Else NULL
		End as Forced,
		BaseOffer
from Staging.OPE_Offers as OO
'+@Joins+'
Left Outer Join Staging.OPE_Offers_Forced as oof
	on	oo.IronOfferID = oof.OfferID and
		(oo.HTMID = oof.HTMID or oof.HTMID is null) and
		--oof.ForcedInTop = 1 and
		oof.EmailDate = Cast('''+CONVERT(varchar, @EmailSendDate, 120)+''' as date)
Group By oo.IronOfferID,oo.PartnerID,oo.HTMID,BaseOffer,
		 Case
			When oof.OfferID is not null then 15000+oof.Score
			Else NULL
		 End
) as a'

--Select @Qry
Exec sp_ExecuteSQL @Qry


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'OPE_01_Create_Weighting_Table' and
		TableSchemaName = 'Staging' and
		TableName = 'OPE_Offers_Weighted' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Update  staging.JobLog_Temp
--Set		TableRowCount = (Select Count(*) from Staging.OPE_Offers_Weighted)
--where	StoredProcedureName = 'OPE_01_Create_Weighting_Table' and
--		TableSchemaName = 'Staging' and
--		TableName = 'OPE_Offers_Weighted' and
--		TableRowCount is null

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
