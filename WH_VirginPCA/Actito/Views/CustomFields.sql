


CREATE VIEW [Actito].[CustomFields]
AS

SELECT	FanID = v.FanID	-- CUSTOM FIELDS
	,	CustomField1 = COALESCE([CustomField1], '')
	,	CustomField2 = COALESCE([CustomField2], '')
	,	CustomField3 = COALESCE([CustomField3], '')
	,	CustomField4 = COALESCE([CustomField4], '')
	,	CustomField5 = COALESCE([CustomField5], '')
	,	CustomField6 = COALESCE([CustomField6], '')
	,	CustomField7 = COALESCE([CustomField7], '')
	,	CustomField8 = COALESCE([CustomField8], '')
	,	CustomField9 = COALESCE([CustomField9], '')
	,	CustomField10 = COALESCE([CustomField10], '')
	,	CustomField11 = COALESCE([CustomField11], '')
	,	CustomField12 = COALESCE([CustomField12], '')
FROM [WH_VirginPCA].[Email].[DailyData] v
WHERE COALESCE([CustomField1], [CustomField2], [CustomField3], [CustomField4], [CustomField5], [CustomField6], [CustomField7], [CustomField8], [CustomField9], [CustomField10]) IS NOT NULL
AND [CustomField11] IS NOT NULL
AND [CustomField12] IS NOT NULL
EXCEPT
SELECT	FanID = v.FanID	-- CUSTOM FIELDS
	,	CustomField1 = COALESCE([CustomField1], '')
	,	CustomField2 = COALESCE([CustomField2], '')
	,	CustomField3 = COALESCE([CustomField3], '')
	,	CustomField4 = COALESCE([CustomField4], '')
	,	CustomField5 = COALESCE([CustomField5], '')
	,	CustomField6 = COALESCE([CustomField6], '')
	,	CustomField7 = COALESCE([CustomField7], '')
	,	CustomField8 = COALESCE([CustomField8], '')
	,	CustomField9 = COALESCE([CustomField9], '')
	,	CustomField10 = COALESCE([CustomField10], '')
	,	CustomField11 = COALESCE([CustomField11], '')
	,	CustomField12 = COALESCE([CustomField12], '')
FROM [WH_VirginPCA].[Email].[DailyData_PreviousDay] v

