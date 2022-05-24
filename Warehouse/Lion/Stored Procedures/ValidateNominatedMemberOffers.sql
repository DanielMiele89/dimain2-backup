CREATE PROCEDURE [lion].[ValidateNominatedMemberOffers]
	@LionSendID int,
	@LionSendComponentTypeId int,
	@NumberOfItems int,
	@min_count int output
AS
BEGIN
	
	SET NOCOUNT ON;

    select @min_count=isnull(MIN(c),0) from
				(
					select COUNT(*) c
					from Lion.NominatedLionSendComponent
					where LionSendID=@LionSendID and TypeID=@LionSendComponentTypeId and ItemRank <= @NumberOfItems
					group by CompositeId
				) x
END
