CREATE Procedure [Staging].[ShareOfWallet_SegmentAssignment_Prior35_00_V1_4] @PartnerString varchar(20), @IndNonCIN bit
with execute as owner
As

Declare @PartnerID int, @PartnerName varchar(35)

--Set @PartnerString = '3756'
Set @Partnerid = Cast(Left(@PartnerString,4)  as int)
Set @PartnerName = (Select Partnername_formated from Warehouse.relational.PartnerStrings where @PartnerString = Partnerstring)
--Select @PartnerID,@PartnerString,@PartnerName

Exec [Staging].[ShareOfWallet_SegmentAssignment_Prior35_01_V1_2] @PartnerString
exec [Staging].[ShareOfWallet_SegmentAssignment_Prior35_02_V1_3] @PartnerName,@PartnerID,@PartnerString
--exec [Staging].[ShareOfWallet_SegmentAssignment_03_V1] @PartnerString

--if @IndNonCIN = 1
--Begin
--	Exec [Staging].[ShareOfWallet_NonCinListCustomers]
--End
