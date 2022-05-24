-- =============================================
-- Author:		JEA
-- Create date: 05/04/2016
-- Description:	Returns weekly retailer summary information
-- designed to return results according to a data-driven subscription
-- =============================================
CREATE PROCEDURE [MI].[RewardWeeklySummaryParamsAutofile_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT m.PartnerID
		, p.PartnerName
	FROM Relational.Master_Retailer_Table m
	INNER JOIN Relational.[Partner] p ON m.PartnerID = p.PartnerID
	LEFT OUTER JOIN MI.RewardWeeklySummary_CustomStartDate cs ON m.PartnerID = cs.PartnerID
	WHERE m.Advertised_Launch_Date IS NOT NULL
	AND cs.StopDate IS NULL

END