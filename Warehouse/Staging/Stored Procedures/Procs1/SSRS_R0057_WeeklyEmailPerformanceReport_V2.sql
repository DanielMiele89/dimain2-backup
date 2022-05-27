

-- *******************************************************************************
-- Author: Suraj Chahal
-- Create date: 02/12/2014
-- Description: Find Campaign Key,Email Name,Customer Journey Status,Week Number,Number of Emails Delivered,
-- Open Rate,Click Through Rate,Unsubscribed Rate
-- *******************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0057_WeeklyEmailPerformanceReport_V2]
			
AS
BEGIN
	SET NOCOUNT ON;


SELECT	*
FROM Warehouse.Staging.R_0057_DataTableV2
ORDER BY StartOfWeek,SendDate,ClubID, CampaignName, CustomerJourneyStatus, WeekNumber

END