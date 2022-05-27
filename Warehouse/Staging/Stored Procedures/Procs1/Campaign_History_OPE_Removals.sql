/*

	Author:				Stuart Barnley

	Date:				01-06-2015

	Purpose:			To copy customers removed by OPE to new table Warehouse.Relational.Campaign_History_OPE_Removal

*/



--Use Warehouse

CREATE Procedure Staging.Campaign_History_OPE_Removals
							@Date Date,
							@SeeChange bit
as

if @SeeChange = 0 
Begin
	----------------------------------------------------------------------------------------------------------
	-----------------------------------------See possible removals--------------------------------------------
	----------------------------------------------------------------------------------------------------------
	Select CH.IronOfferID,Count(*)
	From Relational.Campaign_History as CH
	Left Outer Join Relational.IronOfferMember as IOM
		on	CH.CompositeID = IOM.CompositeID and
			CH.IronOfferID = IOM.IronOfferID

	Where	CH.SDate = @Date and
			CH.GRP = 'Mail' and
			IOM.CompositeID is null
	Group By CH.IronOfferID

	Select Count(*), 'Total Memberships'
	From Relational.Campaign_History as CH
	Left Outer Join Relational.IronOfferMember as IOM
		on	CH.CompositeID = IOM.CompositeID and
			CH.IronOfferID = IOM.IronOfferID

	Where	CH.SDate = @Date and
			CH.GRP = 'Mail' and
			IOM.CompositeID is null
End
if @SeeChange = 1
Begin
	----------------------------------------------------------------------------------------------------------
	------------------Copying entries for customers selected but not added to offer---------------------------
	----------------------------------------------------------------------------------------------------------
	Insert Into Relational.Campaign_History_OPE_Removal
	Select ch.*
	From Relational.Campaign_History as CH
	Left Outer Join Relational.IronOfferMember as IOM
		on	CH.CompositeID = IOM.CompositeID and
			CH.IronOfferID = IOM.IronOfferID
	Where	CH.SDate = @Date and
			CH.GRP = 'Mail' and
			IOM.CompositeID is null
	--(108483 row(s) affected)
----------------------------------------------------------------------------------------------------------
------------------Delete customers selected but not added to offer---------------------------
----------------------------------------------------------------------------------------------------------
	Delete From Relational.Campaign_History
	From Relational.Campaign_History as CH
	Left Outer Join Relational.IronOfferMember as IOM
		on	CH.CompositeID = IOM.CompositeID and
			CH.IronOfferID = IOM.IronOfferID
	Where	CH.SDate = @Date and
			CH.GRP = 'Mail' and
			IOM.CompositeID is null
	--(108483 row(s) affected)
End