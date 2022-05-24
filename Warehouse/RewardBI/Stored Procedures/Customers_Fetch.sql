-- =============================================
-- Author:		JEA
-- Create date: 08/09/2014
-- Description:	Retrieves CBP customers for RewardBI
-- =============================================
create PROCEDURE RewardBI.Customers_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT c.FanID
		, CAST(1 AS TINYINT) AS PublisherID
		, CAST(1 AS TINYINT) AS SchemeID
		, c.DOB
		, c.Gender
		, c.CurrentlyActive AS Active
		, s.ActivatedDate AS ActivationDate
		, COALESCE(s.OptedOutDate, s.DeactivatedDate) AS DeactivationDate
		, c.MarketableByEmail
		, c.ActivatedOffline AS CBP_ActivatedOffline
		, c.POC_Customer AS CBP_IsPOC
		, c.Rainbow_Customer AS CBP_IsRainbow
		, b.BankBrand AS CBP_BankBrand
		, c.Registered AS CBP_Registered
		, ac.[Description] AS CBP_ActivationChannel
	FROM Relational.Customer c
	INNER JOIN MI.CustomerActiveStatus s ON c.FanID = s.FanID
	INNER JOIN SLC_Report.dbo.Fan f ON c.FanID = f.ID
	INNER JOIN SLC_Report.dbo.ActivationChannel ac ON f.ActivationChannel = ac.ID
	INNER JOIN  MI.RewardBI_CBP_Club b ON c.ClubID = b.ClubID

END