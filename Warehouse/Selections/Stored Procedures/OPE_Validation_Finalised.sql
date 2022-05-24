CREATE PROCEDURE [Selections].[OPE_Validation_Finalised] (@Date Date)
	
AS

Begin

	--	Declare @Date Date = '2020-11-05'

Delete
From Warehouse.Selections.OPE_Validation_Input
Where IronOfferID is null
And PartnerName is null

IF OBJECT_ID ('tempdb..#OfferDetailsFromOPE') IS NOT NULL DROP TABLE #OfferDetailsFromOPE
Select IronOfferID
	 , 1001 - ROW_NUMBER() over (order by (select null)) as Weighting
	 , Case
			When IronOfferName like 'Core %' or BaseOffer like 'Core %' then 1
			Else 0
	   End as Base
Into #OfferDetailsFromOPE
From Warehouse.Selections.OPE_Validation_Input eo


-----------------------------------------------------------------------------------------
------------------------------Insert to OfferPrioritisation------------------------------
-----------------------------------------------------------------------------------------

Delete
From Warehouse.Selections.OfferPrioritisation
Where EmailDate = @Date

Insert Into Warehouse.Selections.OfferPrioritisation
Select iof.PartnerID
	 , op.IronOfferID
	 , op.Weighting
	 , op.Base
	 , Case
			When StartDate >= GetDate() Or StartDate Is Null Then 1
			Else 0
	   End as NewOffer
	 , @Date as EmailDate
From #OfferDetailsFromOPE op
Left join SLC_REPL..IronOffer iof
	on op.IronOfferID = iof.ID
	
IF OBJECT_ID ('tempdb..#NewOfferSelection') IS NOT NULL DROP TABLE #NewOfferSelection
Select Distinct IronOfferID
Into #NewOfferSelection
From Warehouse.Iron.OfferMemberAddition
Where StartDate >= @Date

Update op
Set NewOffer = 1
From Warehouse.Selections.OfferPrioritisation op
inner join #NewOfferSelection nos
	on op.IronOfferID = nos.IronOfferID
Where op.EmailDate = @Date

End