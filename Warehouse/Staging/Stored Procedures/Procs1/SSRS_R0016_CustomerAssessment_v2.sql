/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment
					
	Update:			Updated on 2018-10-11 by RF to include Burn offers
					
*/
Create Procedure [Staging].[SSRS_R0016_CustomerAssessment_v2] (@LionSendID Int)
as
Begin

	Declare @LSID Int = @LionSendID

	If Object_ID('tempdb..#SelectedCusts') Is Not Null Drop Table #SelectedCusts
	Select Distinct
		   LionSendID
		 , Convert(Date, nl.Date) as UploadDate
		 , CompositeID
	Into #SelectedCusts
	From Lion.NominatedLionSendComponent nl with (nolock)
	Where LionSendID = @LSID


	If Object_ID('tempdb..#CustomerStats') Is Not Null Drop Table #CustomerStats
	Select LionSendID
		 , UploadDate
		 , Count(Distinct nl.CompositeID) as SelectedCustomerCount
		 , Count(Case When c.CurrentlyActive = 1 Then nl.CompositeID Else NULL End) as Currently_Activated
		 , Count(Case When c.CurrentlyActive = 1 And MarketableByEmail = 1 Then nl.CompositeID Else NULL End) as Currently_MarketableByEmail
		 , Count(Case When c.CurrentlyActive = 0 Then nl.CompositeID Else NULL End) as Deactivated
	Into #CustomerStats
	From #SelectedCusts nl
	Left join Relational.Customer c with (nolock)
		  on nl.CompositeID = c.CompositeID
	Group by LionSendID
		   , UploadDate

End