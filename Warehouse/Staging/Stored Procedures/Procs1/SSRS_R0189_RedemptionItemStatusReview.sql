
CREATE PROCEDURE [Staging].[SSRS_R0189_RedemptionItemStatusReview]

AS
BEGIN


	/***********************************************************************************************************************
						  Declare variables
	***********************************************************************************************************************/

		Declare @GetDate DateTime = GetDate()
			  , @PreviousTwoWeeks Date = DateAdd(Day, -14, GetDate())


	/***********************************************************************************************************************
						  Get transaction counts for each Redemption over the past two weeks
	***********************************************************************************************************************/

		If Object_ID('tempdb..#RedemptionsPreviousTwoWeeks') Is Not Null Drop Table #RedemptionsPreviousTwoWeeks
		Select ItemID
			 , Count(1) as Transactions
		Into #RedemptionsPreviousTwoWeeks
		From SLC_Report..Trans tr
		Where tr.TypeID = 3
		And tr.ProcessDate Between @PreviousTwoWeeks And @GetDate
		Group by ItemID

		Create Clustered Index CIX_RedemptionsPreviousTwoWeeks_ItemID On #RedemptionsPreviousTwoWeeks (ItemID)

	/***********************************************************************************************************************
						  Generate a list of Redmeptions that may need the status updated
	***********************************************************************************************************************/


		If Object_ID('tempdb..#RedemptionsToReview') Is Not Null Drop Table #RedemptionsToReview
		Select ri.RedeemID
			 , ri.RedeemType
			 , ri.PrivateDescription
			 , ri.Status
			 , rptw.Transactions as TransactionsPreviousTwoWeeks
			 , Case
					When ri.Status = 0 And rptw.Transactions Is Not Null Then 'Redemption now tracking transactions, set to live'
					When ri.Status = 1 And rptw.Transactions Is Null Then 'Live Redmeption has no transaction for the previous two weeks'
					When ri.Status Is Null And rptw.Transactions Is Not Null Then 'New Redemption set up and live'
					When ri.Status Is Null And rptw.Transactions Is Null Then 'New Redemption set up but not live yet'
			   End as StatusCondition
			 , Case
					When ri.Status = 0 And rptw.Transactions Is Not Null Then 'Update Warehouse.Relational.RedemptionItem Set Status = 1 Where RedeemID = ' + Convert(VarChar(15), RedeemID) + '
Update Warehouse.Staging.RedemptionItem Set Status = 1 Where RedeemID = ' + Convert(VarChar(15), RedeemID)
					When ri.Status = 1 And rptw.Transactions Is Null Then 'Update Warehouse.Relational.RedemptionItem Set Status = 0 Where RedeemID = ' + Convert(VarChar(15), RedeemID) + '
Update Warehouse.Staging.RedemptionItem Set Status = 0 Where RedeemID = ' + Convert(VarChar(15), RedeemID)
					When ri.Status Is Null And rptw.Transactions Is Not Null Then 'Update Warehouse.Relational.RedemptionItem Set Status = 1 Where RedeemID = ' + Convert(VarChar(15), RedeemID) + '
Update Warehouse.Staging.RedemptionItem Set Status = 1 Where RedeemID = ' + Convert(VarChar(15), RedeemID)
					When ri.Status Is Null And rptw.Transactions Is Null Then 'Update Warehouse.Relational.RedemptionItem Set Status = 0 Where RedeemID = ' + Convert(VarChar(15), RedeemID) + '
Update Warehouse.Staging.RedemptionItem Set Status = 0 Where RedeemID = ' + Convert(VarChar(15), RedeemID)
			   End as StatusUpdate
		From Warehouse.Relational.RedemptionItem ri
		Left join #RedemptionsPreviousTwoWeeks rptw
			on ri.RedeemID = rptw.ItemID
		Where RedeemID Not In (7251, 7252)
		And ((ri.Status = 0 And rptw.Transactions Is Not Null) Or
			 (ri.Status = 1 And rptw.Transactions Is Null) Or
			  ri.Status Is Null)


End
