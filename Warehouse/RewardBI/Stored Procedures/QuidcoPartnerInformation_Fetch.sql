-- =============================================
-- Author:		JEA
-- Create date: 02/02/2015
-- Description:	Sources partner information for Quidco
-- =============================================
CREATE PROCEDURE RewardBI.QuidcoPartnerInformation_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT ID
		, PartnerName
		, PartnerID
		, StartDate
		, EndDate
		, Cashback
		, Quidco
		, Reward
	FROM InsightArchive.QuidcoPartnerInformation

END
