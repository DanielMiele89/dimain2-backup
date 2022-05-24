-- =============================================
-- Author:		JEA
-- Create date: 13/12/2012
-- Description:	Returns admin recipient for campaign emails
-- =============================================
CREATE FUNCTION [MI].[CampaignReport_Recipients]
()
RETURNS NVARCHAR(500)
AS
BEGIN
	
	RETURN 'hayden.reid@rewardinsight.com'
END