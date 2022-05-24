
-- ====================================================================================
-- Author:		Shikha
-- Create date: 2015-11-06
-- Description:	First level of Validation of members for an Offer.
--				
-- Change Log:
-- ========================================================================================

CREATE PROCEDURE [iron].[ValidateOfferMembers] 	
	@OfferID int,
	@Resultmessage varchar(1024) output,
	@ResultCode int output,
	@RowCount int output
AS
 

SET NOCOUNT ON

BEGIN

	--check data availability in Analytics
	select @RowCount = count(1) from [iron].[OfferMember] where IronOfferID = @OfferID 

	--check if the analytics table is populated
	if @RowCount = 0
	begin
		select @Resultmessage = 'There are no members associated with the offer.'
		select @ResultCode = 3
		return
	end

	if exists (
		select CompositeId 
			from [iron].[NominatedOfferMember]
		where IronOfferId = @OfferID
		group by CompositeId
			having count(1) > 1
	)
	select @Resultmessage = 'Members have been assigned multiple times for the Iron offer: ' + convert(varchar(10),@OfferID)
	select @ResultCode = 4


END


