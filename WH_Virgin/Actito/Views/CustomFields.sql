
CREATE VIEW [Actito].[CustomFields]
AS

SELECT	FanID = v.FanID	-- CUSTOM FIELDS
	,	CustomField1 = [CustomField1]
	,	CustomField2 = [CustomField2]
	,	CustomField3 = [CustomField3]
	,	CustomField4 = [CustomField4]
	,	CustomField5 = [CustomField5]
	,	CustomField6 = [CustomField6]
	,	CustomField7 = [CustomField7]
	,	CustomField8 = [CustomField8]
	,	CustomField9 = [CustomField9]
	,	CustomField10 = [CustomField10]
	,	CustomField11 = [CustomField11]
	,	CustomField12 = [CustomField12]
FROM [Email].[DailyData] v
WHERE COALESCE([CustomField1], [CustomField2], [CustomField3], [CustomField4], [CustomField5], [CustomField6], [CustomField7], [CustomField8], [CustomField9], [CustomField10]) IS NOT NULL
OR [CustomField11] IS NOT NULL
OR [CustomField12] IS NOT NULL

