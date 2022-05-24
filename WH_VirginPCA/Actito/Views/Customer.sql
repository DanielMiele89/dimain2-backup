



CREATE VIEW [Actito].[Customer] 
AS

WITH
NewOrUpdated AS (	SELECT	[EmailAddress] = CONVERT(NVARCHAR(50), dd.[Email])
						,	[FanID] = dd.[FanID]
						,	[CIN] = COALESCE(c.SourceUID, '')
						,	[ClubID] = dd.[PublisherID]
					--	,	[ClubName]
						,	[Title] = ''
						,	[FirstName] = dd.[FirstName]
						,	[LastName] = dd.[LastName]
						,	[DOB] = dd.[DOB]
						,	[Gender] = ''
						,	[PartialPostCode] = dd.[PartialPostCode]
						,	[FromAddress] = ''
						,	[FromName] = ''
						,	[CashbackAvailable] = CAST(dd.[CashbackAvailable] AS NVARCHAR(50))
						,	[CashbackPending] = CAST(dd.[CashbackPending] AS NVARCHAR(50))
						,	[LifetimeValue] = CAST(dd.[CashbackLTV] AS NVARCHAR(50))
						,	[AgreedTcsDate] = ''
						,	[CustomerSegment] = ''
						,	[LoyaltyAccount] = ''
						,	[JointAccount] = ''
						,	[IsDebit] = 1
						,	[IsCredit] = 0
						,	[Nominee] = ''
						,	[RBSNomineeChange] = ''
						,	[Marketable] = dd.[Marketable]
					FROM [Email].[DailyData] dd
					LEFT JOIN [Derived].[Customer] c 
						ON c.FanID = dd.FanID
					WHERE NOT EXISTS (	SELECT 1
										FROM [Email].[SampleCustomersList] sclt
										WHERE dd.FanID = sclt.FanID)),

SampleCustomers AS (SELECT	[EmailAddress] = CONVERT(NVARCHAR(50), sclt.[EmailAddress])
						,	[FanID] = sclt.[FanID]
						,	[CIN] = COALESCE(cu.[SourceUID], '')
						,	[ClubID] = dd.[PublisherID]
					--	,	[ClubName]
						,	[Title] = ''
						,	[FirstName] = CAST(LEFT(sclt.[EmailAddress], CHARINDEX('@', sclt.[EmailAddress]) - 1) AS NVARCHAR(64))
						,	[LastName] = CAST(sclt.[FanID] AS NVARCHAR(64))
						,	[DOB] = COALESCE(dd.[DOB], '1900-01-01')
						,	[Gender] = ''
						,	[PartialPostCode] = CAST(COALESCE(dd.[PartialPostCode], '') AS NVARCHAR(5))
						,	[FromAddress] = ''
						,	[FromName] = ''
						,	[CashbackAvailable] = CAST(COALESCE(dd.[CashbackAvailable], '0.00') AS NVARCHAR(50))
						,	[CashbackPending] = CAST(COALESCE(dd.[CashbackPending], '0.00') AS NVARCHAR(50))
						,	[LifetimeValue] = CAST(COALESCE(dd.[CashbackLTV], '0.00') AS NVARCHAR(50))
						,	[AgreedTcsDate] = ''
						,	[CustomerSegment] = ''
						,	[LoyaltyAccount] = ''
						,	[JointAccount] = ''
						,	[IsDebit] = 1
						,	[IsCredit] = 0
						,	[Nominee] = ''
						,	[RBSNomineeChange] = ''
						,	[Marketable] = COALESCE([Marketable], 0)
					FROM [Email].[SampleCustomersList] sclt
					LEFT JOIN [Email].[SampleCustomerLinks] sclk
						ON sclt.ID = sclk.SampleCustomerID
					LEFT JOIN [Email].[DailyData] dd
						ON sclt.FanID = dd.FanID
					LEFT JOIN [Derived].[Customer] cu
						ON sclk.RealCustomerFanID = cu.FanID
					WHERE sclt.ID > 750)

	SELECT	EmailAddress
		,	FanID
		,	CIN
		,	ClubID
	--	,	[ClubName]
		,	Title
		,	FirstName
		,	LastName
		,	DOB
		,	Gender
		,	PartialPostCode
		,	FromAddress
		,	FromName
		,	CashbackAvailable
		,	CashbackPending
		,	LifetimeValue
		,	AgreedTcsDate
		,	CustomerSegment
		,	LoyaltyAccount
		,	JointAccount
		,	IsDebit
		,	IsCredit
		,	Nominee
		,	RBSNomineeChange
		,	Marketable
	FROM NewOrUpdated n
	WHERE NOT EXISTS (	SELECT 1
						FROM SampleCustomers sc
						WHERE n.FanID = sc.FanID)

	UNION

	SELECT	EmailAddress
		,	FanID
		,	COALESCE((SELECT CONVERT(VARCHAR(24), LionSendID) FROM [Email].[OfferSlotData] osd WHERE sc.FanID = osd.FanID), '') AS CIN
		,	ClubID
	--	,	[ClubName]
		,	Title
		,	FirstName
		,	LastName
		,	DOB
		,	Gender
		,	PartialPostCode
		,	FromAddress
		,	FromName
		,	CashbackAvailable
		,	CashbackPending
		,	LifetimeValue
		,	AgreedTcsDate
		,	CustomerSegment
		,	LoyaltyAccount
		,	JointAccount
		,	IsDebit
		,	IsCredit
		,	Nominee
		,	RBSNomineeChange
		,	Marketable
	FROM SampleCustomers sc


GO
DENY SELECT
    ON [Actito].[Customer] ([LastName]) TO [New_Insight]
    AS [New_DataOps];


GO
DENY SELECT
    ON [Actito].[Customer] ([FromName]) TO [New_Insight]
    AS [New_DataOps];


GO
DENY SELECT
    ON [Actito].[Customer] ([FromAddress]) TO [New_Insight]
    AS [New_DataOps];


GO
DENY SELECT
    ON [Actito].[Customer] ([FirstName]) TO [New_Insight]
    AS [New_DataOps];


GO
DENY SELECT
    ON [Actito].[Customer] ([EmailAddress]) TO [New_Insight]
    AS [New_DataOps];


GO
DENY SELECT
    ON [Actito].[Customer] ([DOB]) TO [New_Insight]
    AS [New_DataOps];

