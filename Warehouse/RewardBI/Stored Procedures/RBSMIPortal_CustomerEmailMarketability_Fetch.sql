
-- =============================================
-- Author:		JEA
-- Create date: 26/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerEmailMarketability_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @NULLDATE DATE

	SET @NULLDATE = DATEADD(YEAR, 10, GETDATE())

    SELECT m.ID
		, m.FanID
		, t.[Description] AS MarketabilityStatus
		, m.StartDate
		, ISNULL(m.EndDate, @NULLDATE) AS EndDate
	FROM Relational.Customer_MarketableByEmailStatus_MI m
	INNER JOIN Relational.Customer_MarketableByEmailStatusTypes_MI t ON m.MarketableID = t.ID
	INNER JOIN MI.CustomerActiveStatus cu ON m.FanID = cu.FanID

END

