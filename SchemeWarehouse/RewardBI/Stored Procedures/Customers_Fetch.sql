
-- =============================================
-- Author:		JEA
-- Create date: 08/09/2014
-- Description:	Retrieves CBP customers for RewardBI
-- =============================================
CREATE PROCEDURE [RewardBI].[Customers_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, CAST(2 AS TINYINT) AS PublisherID
		, CAST(2 AS TINYINT) AS SchemeID
		, c.DOB
		, c.Gender
		, c.CurrentlyActive AS Active
		, s.ActivatedDate AS ActivationDate
		, COALESCE(s.OptedOutDate, s.DeactivatedDate) AS DeactivationDate
		, c.MarketableByEmail
		, p.GiftAid AS PForL_GiftAid
		, CAST(CASE WHEN ISNULL(p.EmployerMatchingCode,'') = '' THEN 0 ELSE 1 END AS BIT) AS PForL_EmployerMatch
		, p.MaxMonthlyDonation AS PForL_DonationCap
		, p.DonationAmount AS PForL_DonationValue
		
	FROM Relational.Customer c
		INNER JOIN RewardBI.CustomerActiveStatus s ON c.FanID = s.FanID
		INNER JOIN Relational.Customer_DonationPreferences_PfL p ON c.FanID = p.FanID

END

