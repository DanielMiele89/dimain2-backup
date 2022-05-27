CREATE Procedure Staging.LionSendComponent_Deletion (@LionSendID int)
As
Declare @LSID int,@InTable int

Set @LSID = @LionSendID


Set @InTable = (Select Coalesce(COUNT(*),0) 
				From Relational.CampaignLionSendIDs as cls 
				Where LionSendID = @LSID
			    )
if @InTable >= 1 
Begin 
	Select  'Table in Relational.CampaignLionSendIDs'
End
if @InTable = 0
Begin
	Declare @Loops Real,@Loop int
	Set @Loop = 1
	Set @Loops = (Select CasT(COUNT(*) as real) as Loops From Relational.LionSendComponent as lsc Where LionSendID = @LSID)/10000
	
	While @Loop <= @Loops
	Begin 
		Delete Top (10000) From Relational.LionSendComponent
		Where LionSendID = @LSID
	
		Set @Loop = @Loop+1
	
	End
End