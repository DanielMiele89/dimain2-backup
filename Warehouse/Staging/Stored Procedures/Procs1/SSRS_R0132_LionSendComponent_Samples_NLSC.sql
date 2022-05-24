/*

	Author:		Stuart Barnley

	Date:		23th September 2016

	Purpose:	To add the members to nominated LionSendComponent

*/

CREATE Procedure [Staging].[SSRS_R0132_LionSendComponent_Samples_NLSC] (@LionSendID_Full int,@LionSendID_Sample int)
as

Declare @LS_Full int, @LS_Sample int
Set @LS_Full = @LionSendID_Full
Set @LS_Sample = @LionSendID_Sample

Insert Into Lion.NominatedLionSendComponent
Select	Distinct
		@LS_Sample as LionSendID,
		n.CompositeId,
		n.TypeID,
		n.ItemRank,
		n.ItemID,
		n.Date
From Staging.R_0132_LionSendComponent_Sample as a
inner join Lion.NominatedLionSendComponent as n
	on a.CompositeID = n.CompositeId
Where LionSendID= @LS_Full
