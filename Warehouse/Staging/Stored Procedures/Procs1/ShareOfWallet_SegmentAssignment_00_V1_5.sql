CREATE Procedure [Staging].[ShareOfWallet_SegmentAssignment_00_V1_5] @PartnerString varchar(20), @IndNonCIN bit
As

Declare @PartnerID int, @PartnerName varchar(35)

--Set @PartnerString = '3756'
Set @Partnerid = Cast(Left(@PartnerString,4)  as int)
Set @PartnerName = (Select Partnername_formated from Warehouse.relational.PartnerStrings where @PartnerString = Partnerstring)
--Select @PartnerID,@PartnerString,@PartnerName

Exec [Staging].[ShareOfWallet_SegmentAssignment_01_V1_2] @PartnerString
exec [Staging].[ShareOfWallet_SegmentAssignment_02_V1_4] @PartnerName,@PartnerID,@PartnerString
exec [Staging].[ShareOfWallet_SegmentAssignment_04_V1] @PartnerID

if @IndNonCIN = 1
Begin
	Exec [Staging].[ShareOfWallet_NonCinListCustomers]
End
