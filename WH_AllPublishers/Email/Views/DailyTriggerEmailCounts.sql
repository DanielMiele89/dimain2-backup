
CREATE VIEW [Email].[DailyTriggerEmailCounts]
AS

SELECT	tec.TriggerEmail
	 ,	tec.SendDate
	 ,	tec.Brand AS Publisher
	 ,	tec.Loyalty AS Segment
	 ,	tec.CustomersEmailed
FROM [Warehouse].[SmartEmail].[DailyData_TriggerEmailCounts] tec

UNION ALL

SELECT	tet.TriggerEmail
	,	tec.EmailSendDate
	,	cl.Name AS Publisher
	,	cu.AccountType AS Segment
	,	COUNT(DISTINCT tec.FanID) AS CustomersEmailed
FROM [WH_VirginPCA].[Email].[TriggerEmailCustomers] tec
INNER JOIN [WH_VirginPCA].[Email].[TriggerEmailType] tet
	ON tec.TriggerEmailTypeID = tet.ID
INNER JOIN [WH_VirginPCA].[Derived].[Customer] cu
	ON tec.FanID = cu.FanID
LEFT JOIN [SLC_REPL].[dbo].[Club] cl
	ON cu.ClubID = cl.ID
GROUP BY	tet.TriggerEmail
		,	tec.EmailSendDate
		,	cl.Name
		,	cu.AccountType

UNION ALL

SELECT	tet.TriggerEmail
	,	tec.EmailSendDate
	,	cl.Name AS Publisher
	,	cu.AccountType AS Segment
	,	COUNT(DISTINCT tec.FanID) AS CustomersEmailed
FROM [WH_Virgin].[Email].[TriggerEmailCustomers] tec
INNER JOIN [WH_Virgin].[Email].[TriggerEmailType] tet
	ON tec.TriggerEmailTypeID = tet.ID
INNER JOIN [WH_Virgin].[Derived].[Customer] cu
	ON tec.FanID = cu.FanID
INNER JOIN [SLC_REPL].[dbo].[Club] cl
	ON cu.ClubID = cl.ID
GROUP BY	tet.TriggerEmail
		,	tec.EmailSendDate
		,	cl.Name
		,	cu.AccountType

UNION ALL

SELECT	tet.TriggerEmail
	,	tec.EmailSendDate
	,	cl.Name AS Publisher
	,	COALESCE(cu.AccountType, '') AS Segment
	,	COUNT(DISTINCT tec.FanID) AS CustomersEmailed
FROM [WH_Visa].[Email].[TriggerEmailCustomers] tec
INNER JOIN [WH_Visa].[Email].[TriggerEmailType] tet
	ON tec.TriggerEmailTypeID = tet.ID
INNER JOIN [WH_Visa].[Derived].[Customer] cu
	ON tec.FanID = cu.FanID
INNER JOIN [SLC_REPL].[dbo].[Club] cl
	ON cu.ClubID = cl.ID
GROUP BY	tet.TriggerEmail
		,	tec.EmailSendDate
		,	cl.Name
		,	cu.AccountType
