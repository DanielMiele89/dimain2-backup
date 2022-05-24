/*

	Author:			Stuart Barnley
	
	Date:			24th November 2016
	
	Purpose:		Add Entries to Staging.LionSendLoads table, if entries are present do not overwrite


*/

CREATE Procedure Staging.R_0141CampaignEmailLoadingandSendingStats (@LionSendID int)
As

Declare @LSID int

Set @LSID = @LionSendID

If @LSID not in (Select LionSendID From Staging.LionSendLoads)
Begin
	Insert into Staging.LionSendLoads
	Select	LionSendID, 
			Count(*) as LoadedByDI,
			NULL as LoadedByGAS,
			NULL as EmailsSent
	From Lion.NominatedLionSendComponent
	Where LionSendID = @LSID
	Group by LionSendID

	Select 'New Row Added'
End



If @LSID in (Select LionSendID From Staging.LionSendLoads) and
			(Select LoadedByGAS From Staging.LionSendLoads Where LionSendID = @LionSendID) = NUll
Begin
	Update Staging.LionSendLoads
	Set LoadedByGAS = (Select TotalMembers from slc_report.Lion.LionSend Where ID = @LSID)
	Where LionSendID = @LSID

	Select 'Updated LoadedByGas'
End