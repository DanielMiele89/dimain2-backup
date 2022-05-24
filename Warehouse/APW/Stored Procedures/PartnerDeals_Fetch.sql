-- =============================================
-- Author:		JEA
-- Create date: 01/12/2016
-- Description:	Fetches partner deals for SchemeTrans population on REWARDBI
-- =============================================
CREATE PROCEDURE [APW].[PartnerDeals_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT ClubID AS PublisherID
		, PartnerID
		, ManagedBy
		, StartDate
		, EndDate
		, CAST(Publisher AS varchar(50)) as Publisher
		, CAST(Reward AS varchar(50)) AS Reward
	FROM Relational.nFI_Partner_Deals

END