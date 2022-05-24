-- =============================================
-- Author:		JEA
-- Create date: 04/07/2014
-- Description:	Returns weekly retailer summary information
-- designed to return results according to a data-driven subscription
-- =============================================
CREATE PROCEDURE [MI].[RewardWeeklySummaryRetailer_SubscriptionParameters_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT m.PartnerID
		, 'Reward Weekly Summary Report - ' + p.PartnerName AS EmailSubject
		--, ISNULL(e.ContactEmail + '; ed.allison@rewardinsight.com; prakash.kelshiker@rewardinsight.com',  'ed.allison@rewardinsight.com') AS EmailToList
		, 'rosheela.coomaraswamy@rewardinsight.com; christine.tarves@rewardinsight.com; ed.allison@rewardinsight.com; prakash.kelshiker@rewardinsight.com' AS EmailToList
		--, 'valentina.lupi@rewardinsight.com;nick.leyland@rewardinsight.com;tom.peace@rewardinsight.com;ed.allison@rewardinsight.com' AS EmailToList
	FROM Relational.Master_Retailer_Table m
	INNER JOIN Relational.[Partner] p ON m.PartnerID = p.PartnerID
	LEFT OUTER JOIN Warehouse.Staging.Reward_StaffTable e ON e.StaffID = m.CS_Lead_ID
	LEFT OUTER JOIN MI.RewardWeeklySummary_CustomStartDate cs ON m.PartnerID = cs.PartnerID
	WHERE m.Advertised_Launch_Date IS NOT NULL
	AND cs.StopDate IS NULL

END