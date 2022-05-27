CREATE Procedure [Staging].[OPE_Concept_Offer_ETLV2] (@EmailSendDate Date)
as

-------------------------------------------------------------------------------------------------
----------------------------Create table of offers-----------------------------------------------
-------------------------------------------------------------------------------------------------
--Declare @EmailSendDate date
--Set @EmailSendDate = 'Oct 20, 2014'
Truncate Table Staging.OPE_Offers_TobeScored
Insert into Staging.OPE_Offers_TobeScored
Select	I.IronOfferID,
		Cast(I.StartDate as DATE) as StartDate,
		Cast(I.EndDate as DATE) as EndDate,
		I.PartnerID,
		Cast(null as Int) BaseOffer
--into Staging.OPE_Offers_TobeScored
from Relational.IronOffer as i
Where	StartDate <= @EmailSendDate and
		(EndDate is null or Cast(EndDate as date) > @EmailSendDate) and
		i.IronOfferName not in ('default collateral','spare','above the line collateral','Above The Line','Default','(Demo) special offer')
-------------------------------------------------------------------------------------------------
----------------------------Delete POC triggers that are still open------------------------------
-------------------------------------------------------------------------------------------------		
Delete from Staging.OPE_Offers_TobeScored
Where IronOfferID in 
(Select IronOfferID 
From Relational.IronOffer as i
Where 	i.EndDate is null and
		i.IsTriggerOffer = 1 and 
		i.StartDate < 'Aug 07, 2013')
-------------------------------------------------------------------------------------------------
---------------------------------Remove POC offers not signed off--------------------------------
-------------------------------------------------------------------------------------------------		
Delete From Staging.OPE_Offers_TobeScored
Where IronOfferID in
(	Select IronOfferID 
	From Relational.IronOffer as i
	Where IsSignedOff = 0 and
	CampaignType = 'Pre Full Launch Campaign')
-------------------------------------------------------------------------------------------------
-----------------Remove offers not signed off that start date has passed-------------------------
-------------------------------------------------------------------------------------------------
Delete From Staging.OPE_Offers_TobeScored
Where IronOfferID in
(	Select IronOfferID 
	From Relational.IronOffer as i
	Where i.IsSignedOff = 0 and
	i.StartDate < CAST(getdate() as DATE))
-------------------------------------------------------------------------------------------------
-----------------Add base Offer Flag-------------------------
-------------------------------------------------------------------------------------------------
Update Staging.OPE_Offers_TobeScored
Set BaseOffer = 
		Case
			When a.IronOfferID IS null then 1
			Else 0
		End 
			
From Staging.OPE_Offers_TobeScored as s
Left Outer join 
	(	Select w.IronOfferID
		From Staging.OPE_Offers_TobeScored as w
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
	) as a
		on s.IronOfferID = a.IronOfferID
-------------------------------------------------------------------------------------------------
-----------------execute each SP one by one to generate individual offer scores------------------
-------------------------------------------------------------------------------------------------
--Declare @EmailSendDate date
--Set @EmailSendDate = 'Oct 20, 2014'

Declare		@ConceptID int, 
			@ConceptMax int,
			@Qry nvarchar(max), -- Field to stored the qry to be constructed and run
			@SPName varchar(200) -- name of the stored procedure that will be called
Set @ConceptID = 1
Set @ConceptMax = (Select MAX(ConceptID) from Staging.OPE_Concept)

While @ConceptID <= @ConceptMax
Begin
	Set @SPName = (	select 'Exec ' + Concept_sp 
					from Staging.OPE_Concept 
					where @ConceptID = ConceptID and ETL_Run = 1)
						  
	Set @Qry = 'Declare @EmailDate date Set @EmailDate = '''+convert(varchar,@EmailSendDate,121)+''''+@SPName +' @EmailDate'
	
	Exec Sp_ExecuteSQL @Qry
	
	Set @ConceptID = @ConceptID + 1
End

-------------------------------------------------------------------------------------------------
-----------------------Create values to allow for Offer collation to happen----------------------
-------------------------------------------------------------------------------------------------
Declare @OuterJoins_Offers nvarchar(Max),
		@Fields_Offers nvarchar(Max),
		@OffersCode nvarchar(max)
--********************************************************************************************--
--*********************************Inner Join Statements**************************************--
--********************************************************************************************--
Set @OuterJoins_Offers = (Select OuterJoin+'
' as 'text()'
From
(Select Concept_SP, 'Left Outer join Staging.OPE_Concept_'+ct.[Description]+'_'+ConceptName+' as '+ Char(c.ConceptID+96) + ' on io.IronOfferID = ' + Char(c.ConceptID+96)+'.IronOfferID' as OuterJoin

from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Offer'
) as a
for XML Path ('')
)
Set  @OuterJoins_Offers = Replace(@OuterJoins_Offers,'&#x0D;','')
--********************************************************************************************--
--*********************************Field listing Statements***********************************--
--********************************************************************************************--
Set @Fields_Offers = (Select field+'' as 'text()'
From
(Select 'Coalesce('+Char(c.ConceptID+96)+'.'+ConceptName+',0) as ['+ConceptName+'], ' as field

from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Offer'
) as a
for XML Path ('')
)
Set  @Fields_Offers = Replace(@Fields_Offers,'&#x0D;','')

Set  @Fields_Offers = LEFT(@Fields_Offers,LEN(@Fields_Offers)-1)

--Select @Fields_Offers
--********************************************************************************************--
--**************************Create Code to create offers score table *************************--
--********************************************************************************************--
if object_id('Staging.OPE_Concept_Offer_Scores') is not null drop table Staging.OPE_Concept_Offer_Scores
Set @OffersCode = '
Select io.IronOfferID,
	   '+@Fields_Offers+'
Into Staging.OPE_Concept_Offer_Scores
From Staging.OPE_Offers_TobeScored as io
'+@OuterJoins_Offers
				
Exec sp_executeSQL @OffersCode
-------------------------------------------------------------------------------------------------
-----------------------Create values to allow for Partner collation to happen----------------------
-------------------------------------------------------------------------------------------------
Declare @OuterJoins_Partners nvarchar(Max),
		@Fields_Partners nvarchar(max),
		@PartnersCode nvarchar(max)

Set @OuterJoins_Partners = (Select OuterJoin+'
' as 'text()'
From
(Select Concept_SP, 'Left Outer join Staging.OPE_Concept_'+ct.[Description]+'_'+ConceptName+' as '+ Char(c.ConceptID+96) + ' on p.PartnerID = ' + Char(c.ConceptID+96)+'.PartnerID' as OuterJoin
from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Partner'
) as a
for XML Path ('')
)
Set  @OuterJoins_Partners = Replace(@OuterJoins_Partners,'&#x0D;','')

--********************************************************************************************--
--*********************************Field listing Statements***********************************--
--********************************************************************************************--
Set @Fields_Partners = (Select field+'' as 'text()'
From
(Select 'Coalesce('+Char(c.ConceptID+96)+'.'+ConceptName+',0) as ['+ConceptName+'], ' as field

from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Partner'
) as a
for XML Path ('')
)
Set  @Fields_Partners = Replace(@Fields_Partners,'&#x0D;','')

Set  @Fields_Partners = LEFT(@Fields_Partners,LEN(@Fields_Partners)-1)

--********************************************************************************************--
--**************************Create Code to create offers score table *************************--
--********************************************************************************************--
if object_id('Staging.OPE_Concept_Partner_Scores') is not null drop table Staging.OPE_Concept_Partner_Scores
Set @PartnersCode = '
Select p.PartnerID,
	   '+@Fields_Partners+'
Into Staging.OPE_Concept_Partner_Scores
From Relational.Partner as p
'+@OuterJoins_Partners
				
Exec sp_executeSQL @PartnersCode

--*&*&*&*&*&*&*&*&*&*&*&*&*&*&*&**&*
Declare @OuterJoins_OfferSow nvarchar(Max),
		@Fields_OfferSoW nvarchar(max),
		@Code_OfferSoW nvarchar(max)

Set @OuterJoins_OfferSoW = (Select OuterJoin+'
' as 'text()'
From
(Select Concept_SP, 'Left Outer join Staging.OPE_Concept_OfferSow_'+ConceptName+' as '+ Char(c.ConceptID+96) + ' on aa.IronOfferID = ' +
							Char(c.ConceptID+96)+'.IronOfferID and aa.HTMID = '+Char(c.ConceptID+96)+'.HTMID ' as OuterJoin
from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Offer SoW'
) as a
for XML Path ('')
)
Set  @OuterJoins_OfferSoW = Replace(@OuterJoins_OfferSoW,'&#x0D;','')

--********************************************************************************************--
--*********************************Field listing Statements***********************************--
--********************************************************************************************--
Set @Fields_OfferSoW = (Select field+'' as 'text()'
From
(Select 'Coalesce('+Char(c.ConceptID+96)+'.'+ConceptName+',0) as ['+ConceptName+'], ' as field

from Staging.OPE_Concept as c
inner join Staging.OPE_ConceptType as ct
	on c.ConceptTypeID = ct.ConceptTypeID
Where ETL_Run = 1 and ct.[Description] = 'Offer SoW'
) as a
for XML Path ('')
)
Set  @Fields_OfferSoW = Replace(@Fields_OfferSoW,'&#x0D;','')

Set  @Fields_OfferSoW = LEFT(@Fields_OfferSoW,LEN(@Fields_OfferSoW)-1)

--********************************************************************************************--
--**************************Create Code to create offers score table *************************--
--********************************************************************************************--
if object_id('Staging.OPE_Concept_OfferSoW_Scores') is not null drop table Staging.OPE_Concept_OfferSoW_Scores
Set @Code_OfferSoW = '
Select aa.IronOfferID,
       aa.HTMID,
	   '+@Fields_OfferSoW+'
Into Staging.OPE_Concept_OfferSoW_Scores
From
(
Select	io.IronOfferID,
		ag.HTMID
From Staging.OPE_Offers_TobeScored as io,
Relational.HeadroomTargetingModel_Groups as ag
Where ag.HTMID >= 10
Union All
Select io.IronOfferID, 0 as HTMID
From Staging.OPE_Offers_TobeScored as io
) as aa
'+@OuterJoins_OfferSoW
				
--select @Code_OfferSoW

Exec sp_executeSQL @Code_OfferSoW
