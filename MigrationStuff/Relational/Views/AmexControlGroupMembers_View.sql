CREATE VIEW [Relational].[AmexControlGroupMembers_View]
AS

SELECT	AmexControlGroupID = cgi.OriginalControlGroupID
	,	cgm.FanID
FROM [WH_AllPublishers].[Report].[OfferReport_ControlGroupMembers] cgm
INNER JOIN [WH_AllPublishers].[Report].[ControlSetup_ControlGroupIDs] cgi
	ON cgm.ControlGroupID = cgi.ControlGroupID
WHERE cgi.OriginalTableSource = '[nFI].[Relational].[AmexIronOfferCycles]'