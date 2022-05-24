


CREATE VIEW [Actito].[Customer] 
AS

WITH
NewOrUpdated AS (	SELECT	[EmailAddress] = dd.[Email]
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
						,	[IsDebit] = 0
						,	[IsCredit] = 1
						,	[Nominee] = ''
						,	[RBSNomineeChange] = ''
						,	[Marketable] = dd.[Marketable]
					FROM [Email].[DailyData] dd
					LEFT JOIN [Derived].[Customer] c 
						ON c.FanID = dd.FanID
					WHERE NOT EXISTS (	SELECT 1
										FROM [Email].[SampleCustomersList] sclt
										WHERE dd.FanID = sclt.FanID)),

SampleCustomers AS (SELECT	[EmailAddress] = sclt.[EmailAddress]
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
						,	[IsDebit] = 0
						,	[IsCredit] = 1
						,	[Nominee] = ''
						,	[RBSNomineeChange] = ''
						,	[Marketable] = COALESCE([dd].[Marketable], 0)
					FROM [Email].[SampleCustomersList] sclt
					LEFT JOIN [Email].[SampleCustomerLinks] sclk
						ON sclt.ID = sclk.SampleCustomerID
					LEFT JOIN [Email].[DailyData] dd
						ON sclt.FanID = dd.FanID
					LEFT JOIN [Derived].[Customer] cu
						ON sclk.RealCustomerFanID = cu.FanID
					WHERE sclt.ID <= 750)

	SELECT	[n].[EmailAddress]
		,	[n].[FanID]
		,	[n].[CIN]
		,	[n].[ClubID]
	--	,	[ClubName]
		,	[n].[Title]
		,	[n].[FirstName]
		,	[n].[LastName]
		,	[n].[DOB]
		,	[n].[Gender]
		,	[n].[PartialPostCode]
		,	[n].[FromAddress]
		,	[n].[FromName]
		,	[n].[CashbackAvailable]
		,	[n].[CashbackPending]
		,	[n].[LifetimeValue]
		,	[n].[AgreedTcsDate]
		,	[n].[CustomerSegment]
		,	[n].[LoyaltyAccount]
		,	[n].[JointAccount]
		,	[n].[IsDebit]
		,	[n].[IsCredit]
		,	[n].[Nominee]
		,	[n].[RBSNomineeChange]
		,	[n].[Marketable]
	FROM NewOrUpdated n
	WHERE NOT EXISTS (	SELECT 1
						FROM SampleCustomers sc
						WHERE n.FanID = sc.FanID)

	UNION

	SELECT	[sc].[EmailAddress]
		,	[sc].[FanID]
		,	COALESCE((SELECT CONVERT(VARCHAR(24), [osd].[LionSendID]) FROM [Email].[OfferSlotData] osd WHERE sc.FanID = osd.FanID), '') AS CIN
		,	[sc].[ClubID]
	--	,	[ClubName]
		,	[sc].[Title]
		,	[sc].[FirstName]
		,	[sc].[LastName]
		,	[sc].[DOB]
		,	[sc].[Gender]
		,	[sc].[PartialPostCode]
		,	[sc].[FromAddress]
		,	[sc].[FromName]
		,	[sc].[CashbackAvailable]
		,	[sc].[CashbackPending]
		,	[sc].[LifetimeValue]
		,	[sc].[AgreedTcsDate]
		,	[sc].[CustomerSegment]
		,	[sc].[LoyaltyAccount]
		,	[sc].[JointAccount]
		,	[sc].[IsDebit]
		,	[sc].[IsCredit]
		,	[sc].[Nominee]
		,	[sc].[RBSNomineeChange]
		,	[sc].[Marketable]
	FROM SampleCustomers sc


GO
DENY SELECT
    ON OBJECT::[Actito].[Customer] TO [New_Insight]
    AS [dbo];

