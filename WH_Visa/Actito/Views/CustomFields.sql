
CREATE VIEW [Actito].[CustomFields]
AS

SELECT	FanID = v.FanID	-- CUSTOM FIELDS
	,	CustomField1 =	CONVERT(VARCHAR(255), COALESCE([CustomField1], ''))
	,	CustomField2 =	CONVERT(VARCHAR(255), COALESCE([CustomField2], ''))
	,	CustomField3 =	CONVERT(VARCHAR(255), COALESCE([CustomField3], ''))
	,	CustomField4 =	CONVERT(VARCHAR(255), COALESCE([CustomField4], ''))
	,	CustomField5 =	CONVERT(VARCHAR(255), COALESCE([CustomField5], ''))
	,	CustomField6 =	CONVERT(VARCHAR(255), COALESCE([CustomField6], ''))
	,	CustomField7 =	CONVERT(VARCHAR(255), COALESCE([CustomField7], ''))
	,	CustomField8 =	CONVERT(VARCHAR(255), COALESCE([CustomField8], ''))
	,	CustomField9 =	CONVERT(VARCHAR(255), COALESCE([CustomField9], ''))
	,	CustomField10 = CONVERT(VARCHAR(255), COALESCE([CustomField10], ''))
	,	CustomField11 = CONVERT(VARCHAR(255), COALESCE([CustomField11], ''))
	,	CustomField12 = CONVERT(VARCHAR(255), COALESCE([CustomField12], ''))
FROM [WH_Visa].[Email].[DailyData] v
WHERE COALESCE([CustomField1], [CustomField2], [CustomField3], [CustomField4], [CustomField5], [CustomField6], [CustomField7], [CustomField8], [CustomField9], [CustomField10]) IS NOT NULL
AND [CustomField11] IS NOT NULL
AND [CustomField12] IS NOT NULL

