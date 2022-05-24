
-- =============================================
-- Author:		JEA
-- Create date: 26/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[RBSMIPortal_CustomerLoyaltyInvitations_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT i.ID
		, i.FanID
		, i.SendDate
		, i.Channel
	FROM Relational.Customer_Loyalty_Invites i
	INNER JOIN Relational.Customer cu ON i.FanID = cu.FanID
	INNER JOIN (SELECT FanID
					, MIN(SendDate) AS SendDate
				FROM Relational.Customer_Loyalty_Invites
				GROUP BY FanID
				) m ON i.FanID = m.FanID AND i.SendDate = m.SendDate

END

