

-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description: Retrieves donations for RewardBI
-- =============================================
CREATE PROCEDURE [RewardBI].[Donations_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT d.Donations_PfL_ID AS ID
		, d.FanID
		, CAST(f.CreateDate AS DATE) AS DonationDate
		, d.Amount
		, d.DonationsStatus_PfL_ID AS DonationStatusID
	FROM Relational.Donations_PfL d
	INNER JOIN Relational.DonationFiles_PfL f ON d.DonationFiles_PfL_ID = f.DonationFiles_PfL_ID
	WHERE f.[Status] = 5

END


