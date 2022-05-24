Create Procedure [Staging].[OPE_Concept_Offer_CashbackRate_SP] (@EmailSendDate Date)
as
Begin
--Declare @EmailSendDate date
--Set @EmailSendDate = 'Nov 06, 2014'
---------------------------------------------------------------------------------------------------------------
-----------------------------------------------------Create table of Rates-------------------------------------
---------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Scores') is not null drop table #Scores
Select CAST(Value as real) as Rate, Score, ROW_NUMBER() OVER(ORDER BY Score Asc) AS RowNo
into #Scores
from Staging.OPE_ConceptScore as cs
inner join Staging.OPE_Concept as c
	on cs.ConceptID = c.ConceptID
Where ConceptName = 'Cashback_Rate'

---------------------------------------------------------------------------------------------------------------
------------------------------------Create individual Values for CashbackRate-------------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('tempdb..#t1') is not null drop table #t1
	Select  o.IronOfferID,
			Max(CommissionRate) as Cashbackrate
	Into #t1
	from Staging.OPE_Offers_TobeScored as o
	inner join Relational.IronOffer_PartnerCommissionRule as pcr
		on o.IronOfferID = pcr.IronOfferID
	Where	pcr.TypeID = 1 and
			Status = 1
	Group By o.IronOfferID
---------------------------------------------------------------------------------------------------------------
------------------------------------Create individual Scores for OfferLife-------------------------------------
---------------------------------------------------------------------------------------------------------------
	
	-- Create entries where cashbackrates match
	if object_id('tempdb..#MatchedOffersScored') is not null drop table #MatchedOffersScored
	Select t.IronOfferID,t.Cashbackrate,s.Score
	Into #MatchedOffersScored
	from #t1 as t
	Left Outer join #Scores as s
		on t.Cashbackrate = s.Rate
	
	-- Create entries where cashbackrate needs rounding
	
	if object_id('tempdb..#MatchedOffersScoredOther') is not null drop table #MatchedOffersScoredOther
	Select	T.IronOfferID,
			T.Cashbackrate,
			Case
				When t.Cashbackrate = 0 then 0
				When s.Score IS not null then s.score
				Else 0
			End as Score
	Into #MatchedOffersScoredOther			
	from #t1 as t
	Left Outer join #Scores as s
		on Round(t.Cashbackrate,0) = s.Rate
	left outer join #MatchedOffersScored as m
		on m.IronOfferID = t.IronOfferID
	Where m.Score is null
---------------------------------------------------------------------------------------------------------------
----------------------------Delete table with individual scores for CashbackRate-------------------------------
---------------------------------------------------------------------------------------------------------------
	if object_id('Staging.OPE_Concept_Offer_Cashback_Rate') is not null drop table Staging.OPE_Concept_Offer_Cashback_Rate

---------------------------------------------------------------------------------------------------------------
------------------------------------------------ Add to final table -------------------------------------------
---------------------------------------------------------------------------------------------------------------
	
	Select	IronOfferID,
			Score as Cashback_Rate
	into Staging.OPE_Concept_Offer_Cashback_Rate
	From
		(	Select * 
			from #MatchedOffersScored
			Where Score is not null
			
			Union All
			Select * 
			from #MatchedOffersScoredOther
		) as a
	Order by IronOfferID
	
End