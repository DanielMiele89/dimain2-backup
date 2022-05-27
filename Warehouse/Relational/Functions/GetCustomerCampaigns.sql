CREATE FUNCTION Relational.GetCustomerCampaigns
 (@TotalPerCampaign AS INT) RETURNS TABLE
AS
RETURN
 SELECT TOP(@TotalPerCampaign)
	FanID
 FROM [WH_Virgin].[Derived].[Customer]
 ORDER BY FanID
