/*
	Author: Zoe Taylor

	Date:	26th January 2017

	Pupose:	To remove any previous IronOfferMember addtions for RBSG
	
*/

CREATE Procedure Staging.OfferMemberAdditions_Removal (@RunType tinyint)
As

Declare @StartDate date, @TotalRows int
set @StartDate = getdate()

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
Select OMA.IronOfferID,oma.StartDate,Count(*) as Customers
Into #Offers
From iron.OfferMemberAddition as OMA
inner join relational.ironoffer as i
	on OMA.IronOfferID = i.IronOfferID
Where OMA.StartDate <= @StartDate
Group by oma.IronOfferID,oma.StartDate

Select * from #Offers

If @RunType = 0
Begin
	Select * from #Offers Order by StartDate
End


Set @TotalRows = (Select Sum(Customers)  From #Offers)

Select @TotalRows

--Select #Offers
If @RunType = 1
Begin
	Declare @S int, @E int
	Set @S = 1
	Set @E = (cast(@TotalRows as real) / 10000)+1 

	--Select @E

	While @S <= @E
	Begin 
		Delete top (10000)
		From iron.OfferMemberAddition
		Where IronOfferID in (Select IroNOfferID From #Offers)
		Set @S = @S+1
	End
End