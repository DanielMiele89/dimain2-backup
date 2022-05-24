CREATE VIEW [Report].[ControlGroupMembers_View]
AS

SELECT	ControlGroupID = cgi.OriginalControlGroupID
	,	cgm.FanID
FROM [WH_AllPublishers].[Report].[OfferReport_ControlGroupMembers] cgm
INNER JOIN [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cgi
	ON cgm.ControlGroupID = cgi.ControlGroupID
WHERE cgi.OriginalTableSource = '[WH_Virgin].[Report].[IronOfferCycles]'