CREATE Procedure [Staging].[OPE_Concept_Offer_OfferLife_SP] (@EmailSendDate Date)
as
Begin
--Declare @EmailSendDate date
--Set @EmailSendDate = 'Nov 06, 2014'
---------------------------------------------------------------------------------------------------------------
-----------------------------Delete table with individual scores for OfferLife---------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_Offer_Offer_Life') is not null drop table Staging.OPE_Concept_Offer_Offer_Life

---------------------------------------------------------------------------------------------------------------
------------------------------------Create individual Values for OfferLife-------------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('tempdb..#t1') is not null drop table #t1
	Select  o.IronOfferID,
			Case
				When Cast(StartDate as DATE) = Cast(@EmailSendDate AS DATE) then 'Starting'
				When EndDate Between Dateadd(day,2,@EmailSendDate) and DATEADD(day,6,@EmailSendDate) then 'Ending (3-7 days)'
				When EndDate < Dateadd(day,2,@EmailSendDate) then 'Ending (1-2 days)'
				Else 'Middle'
			End as Offer_Life
	Into #t1
	from Staging.OPE_Offers_TobeScored as o
---------------------------------------------------------------------------------------------------------------
------------------------------------Create individual Scores for OfferLife-------------------------------------
---------------------------------------------------------------------------------------------------------------
	Select  o.IronOfferID,
			Case
				When Offer_Life = 'Starting' then cs.Score
				When Offer_Life = 'Ending (3-7 days)' then cs.Score
				When Offer_Life = 'Ending (1-2 days)' then cs.Score
				When Offer_Life = 'Middle' then cs.Score
				Else 0
			End as Offer_Life
	into Staging.OPE_Concept_Offer_Offer_Life
	from #t1 as o
	inner join Staging.OPE_ConceptScore as cs
		on	o.Offer_Life = cs.Value
	inner join Staging.ope_Concept as c
		on cs.ConceptID = c.ConceptID
	Where c.ConceptName = 'Offer_Life'
End

select * from Staging.OPE_ConceptScore
where ConceptID = 2