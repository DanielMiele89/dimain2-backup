/*
	Author: Stuart Barnley

	Date:	08th February 2017

	Pupose:	To remove any previous IronOfferMember Closures for RBSG
	
*/

CREATE Procedure [Staging].[OfferMemberClosure_Removal] (@RunType tinyint)
As

Declare @StartDate date, @TotalRows int
set @StartDate = getdate()

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
Select OMA.IronOfferID,oma.EndDate,Count(*) as Customers
Into #Offers
From iron.OfferMemberClosure as OMA
inner join relational.ironoffer as i
	on OMA.IronOfferID = i.IronOfferID
Where OMA.Enddate <= @StartDate
Group by oma.IronOfferID,oma.EndDate

Select * from #Offers Order by EndDate

--If @RunType = 0
--Begin
--	Select * from #Offers Order by StartDate
--End


Set @TotalRows = (Select Sum(Customers)  From #Offers)

Select @TotalRows

--Select #Offers
If @RunType = 1
Begin
	Declare @S int, @E int
	Set @S = 1
	Set @E = (cast(@TotalRows as real) / 50000)+1 

	--Select @E

	While @S <= @E
	Begin 
		Delete top (50000)
		From iron.OfferMemberClosure
		Where IronOfferID in (Select IronOfferID From #Offers)
		Set @S = @S+1
	End
End