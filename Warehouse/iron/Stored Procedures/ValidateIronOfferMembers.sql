CREATE PROCEDURE [iron].[ValidateIronOfferMembers] 	
	@OfferID int,
	@Result varchar(1024) output,
	@RowCount int output
AS
-- THIS STORED PROC IS A STUB FOR THE ANALYTICS DATABASE STORED PROC 

SET NOCOUNT ON

BEGIN

	--check data availability in Analytics
	select @RowCount = count(1) from [iron].[NominatedOfferMember] where IronOfferID = @OfferID 

	--check if the analytics table is populated
	if @RowCount = 0
	begin
		select @Result = 'There are no members associated with the offer.'
		return
	end

	if exists (
		select CompositeId 
			from [iron].[NominatedOfferMember]
		where IronOfferId = @OfferID
		group by CompositeId
			having count(1) > 1
	)
	select @Result = 'Members have been assigned multiple times for the Iron offer: ' + convert(varchar(10),@OfferID)


END



GO
GRANT EXECUTE
    ON OBJECT::[iron].[ValidateIronOfferMembers] TO [gas]
    AS [dbo];

