
CREATE VIEW [Actito].[CustomFields]
AS

SELECT	FanID = v.FanID	-- CUSTOM FIELDS
	,	CustomField1 = [v].[CustomField1]
	,	CustomField2 = [v].[CustomField2]
	,	CustomField3 = [v].[CustomField3]
	,	CustomField4 = [v].[CustomField4]
	,	CustomField5 = [v].[CustomField5]
	,	CustomField6 = [v].[CustomField6]
	,	CustomField7 = [v].[CustomField7]
	,	CustomField8 = [v].[CustomField8]
	,	CustomField9 = [v].[CustomField9]
	,	CustomField10 = [v].[CustomField10]
	,	CustomField11 = [v].[CustomField11]
	,	CustomField12 = [v].[CustomField12]
FROM [Email].[DailyData] v
WHERE COALESCE([v].[CustomField1], [v].[CustomField2], [v].[CustomField3], [v].[CustomField4], [v].[CustomField5], [v].[CustomField6], [v].[CustomField7], [v].[CustomField8], [v].[CustomField9], [v].[CustomField10]) IS NOT NULL
OR [v].[CustomField11] IS NOT NULL
OR [v].[CustomField12] IS NOT NULL

