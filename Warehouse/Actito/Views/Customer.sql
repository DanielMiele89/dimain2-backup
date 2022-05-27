

CREATE VIEW [Actito].[Customer] 
AS

WITH
Customers AS (	SELECT	EmailAddress = CAST(v.Email AS NVARCHAR(255))
						,	FanID = v.[FanID]
						,	CIN = COALESCE(c.SourceUID, '') 
						,	ClubID = v.[ClubID]
						,	Title = v.[Title]
						,	FirstName = CAST(v.[FirstName] AS NVARCHAR(64))
						,	LastName = CAST(v.[LastName] AS NVARCHAR(64))
						,	DOB = v.[DOB]
						,	Gender = [Sex]
						,	PartialPostCode = CAST([PartialPostCode] AS NVARCHAR(5))
						,	FromAddress = [FromAddress]
						,	FromName = [FromName]
						,	CashbackAvailable = CAST(v.[ClubCashAvailable] AS NVARCHAR(50))
						,	CashbackPending = CAST(v.[ClubCashPending] AS NVARCHAR(50))
						,	LifetimeValue = CAST(v.[LvTotalEarning] AS NVARCHAR(50))
						,	AgreedTcsDate = CAST([AgreedTcsDate] AS DATE)
						,	CustomerSegment = CAST(v.[IsLoyalty] AS NVARCHAR(50))
						,	LoyaltyAccount = [LoyaltyAccount] 
						,	JointAccount = COALESCE([JointAccount], 0)  
						,	IsDebit = [IsDebit]
						,	IsCredit = [IsCredit]
						,	Nominee = [Nominee]
						,	RBSNomineeChange = [RBSNomineeChange]
						,	Marketable = [Marketable]
					FROM [Warehouse].[SmartEmail].[DailyData] v
					LEFT JOIN [Warehouse].[Relational].[Customer] c 
						ON c.FanID = v.FanID
					WHERE NOT EXISTS (	SELECT 1
										FROM [SmartEmail].[SampleCustomersList] sclt
										WHERE v.FanID = sclt.FanID)

				--	AND 1 = 2
										
					--EXCEPT

					--SELECT	EmailAddress = CAST(v.Email AS NVARCHAR(255))
					--	,	FanID = v.[FanID]
					--	,	CIN = COALESCE(c.SourceUID, '') 
					--	,	ClubID = v.[ClubID]
					----	,	[ClubName]
					--	,	Title = v.[Title]
					--	,	FirstName = CAST(v.[FirstName] AS NVARCHAR(64))
					--	,	LastName = CAST(v.[LastName] AS NVARCHAR(64))
					--	,	DOB = v.[DOB]
					--	,	Gender = [Sex]
					--	,	PartialPostCode = CAST([PartialPostCode] AS NVARCHAR(5))
					--	,	FromAddress = [FromAddress]
					--	,	FromName = [FromName]
					--	,	CashbackAvailable = CAST(v.[ClubCashAvailable] AS NVARCHAR(50))
					--	,	CashbackPending = CAST(v.[ClubCashPending] AS NVARCHAR(50))
					--	,	LifetimeValue = CAST(v.[LvTotalEarning] AS NVARCHAR(50))
					--	,	AgreedTcsDate = CAST([AgreedTcsDate] AS DATE)
					--	,	CustomerSegment = CAST(v.[IsLoyalty] AS NVARCHAR(50))
					--	,	LoyaltyAccount = [LoyaltyAccount] 
					--	,	JointAccount = COALESCE([JointAccount], 0)  
					--	,	IsDebit = [IsDebit]
					--	,	IsCredit = [IsCredit]
					--	,	Nominee = [Nominee]
					--	,	RBSNomineeChange = [RBSNomineeChange]
					--	,	Marketable = [Marketable]
					--FROM [Warehouse].[SmartEmail].[DailyData_PreviousDay] v
					--LEFT JOIN [Warehouse].[Relational].[Customer] c 
					--	ON c.FanID = v.FanID
						),

DeactivatedCustomers AS (	SELECT	EmailAddress = CAST('MyRewardsClosedAccount@RewardInsight.com' AS NVARCHAR(255))
								,	FanID = v.[FanID]
								,	CIN = ''
								,	ClubID = 0
								,	Title = ''
								,	FirstName = CAST('' AS NVARCHAR(64))
								,	LastName = CAST('' AS NVARCHAR(64))
								,	DOB = '1900-01-01'
								,	Gender = CAST('' AS NVARCHAR(1))
								,	PartialPostCode = CAST('' AS NVARCHAR(5))
								,	FromAddress = ''
								,	FromName = ''
								,	CashbackAvailable = CAST(0 AS NVARCHAR(50))
								,	CashbackPending = CAST(0 AS NVARCHAR(50))
								,	LifetimeValue = CAST(0 AS NVARCHAR(50))
								,	AgreedTcsDate = CAST('1900-01-01' AS DATE)
								,	CustomerSegment = ''
								,	LoyaltyAccount = 0 
								,	JointAccount = 0
								,	IsDebit = 0
								,	IsCredit = 0
								,	Nominee = 0
								,	RBSNomineeChange = 0
								,	Marketable = 0
								,	DeactivatedDate
							FROM [Relational].[Customer] v
							WHERE EXISTS (	SELECT 1	
											FROM [SmartEmail].[Actito_CustomersUploaded] acu
											WHERE v.FanID = acu.FanID)
							AND v.CurrentlyActive = 0
							
					--		AND 1 = 2
					
					),

SampleCustomers AS (SELECT	EmailAddress = CAST(sclt.EmailAddress AS NVARCHAR(255))
						,	FanID = sclt.[FanID]
						,	CIN = COALESCE(cu.[SourceUID], '') 
						,	ClubID = COALESCE(dd.[ClubID], sclt.[ClubID])
						,	Title = COALESCE(dd.[Title], '')
						,	FirstName = CAST(LEFT(sclt.EmailAddress, CHARINDEX('@', sclt.EmailAddress) - 1) AS NVARCHAR(64))
						,	LastName = CAST(sclt.[FanID] AS NVARCHAR(64))
						,	DOB = COALESCE(dd.[DOB], '1900-01-01')
						,	Gender = COALESCE([Sex], '')
						,	PartialPostCode = CAST(COALESCE(dd.[PartialPostCode], '') AS NVARCHAR(5))
						,	FromAddress = COALESCE(dd.[FromAddress], '')
						,	FromName = COALESCE(dd.[FromName], '')
						,	CashbackAvailable = CAST(COALESCE(dd.[ClubCashAvailable], 0) AS NVARCHAR(50))
						,	CashbackPending = CAST(COALESCE(dd.[ClubCashPending], 0) AS NVARCHAR(50))
						,	LifetimeValue = CAST(COALESCE(dd.[LvTotalEarning], 0) AS NVARCHAR(50))
						,	AgreedTcsDate = CAST(COALESCE([AgreedTcsDate], '1900-01-01') AS DATE)
						,	CustomerSegment = CAST(COALESCE(dd.[IsLoyalty], sclt.[IsLoyalty]) AS NVARCHAR(50))
						,	LoyaltyAccount = COALESCE([LoyaltyAccount], 0)
						,	JointAccount = COALESCE([JointAccount], 0)
						,	IsDebit = COALESCE([IsDebit], 0)
						,	IsCredit = COALESCE([IsCredit], 0)
						,	Nominee = COALESCE([Nominee], 0)
						,	RBSNomineeChange = COALESCE([RBSNomineeChange], 0)
						,	Marketable = COALESCE([Marketable], 0)
					FROM [SmartEmail].[SampleCustomersList] sclt
					LEFT JOIN [SmartEmail].[SampleCustomerLinks] sclk
						ON sclt.ID = sclk.SampleCustomerID
					LEFT JOIN [SmartEmail].[DailyData] dd
						ON sclt.FanID = dd.FanID
					LEFT JOIN [Relational].[Customer] cu
						ON sclk.RealCustomerFanID = cu.FanID)


SELECT	EmailAddress
	,	FanID
	,	CIN
	,	ClubID
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
FROM Customers n
WHERE NOT EXISTS (	SELECT 1
					FROM SampleCustomers sc
					WHERE n.FanID = sc.FanID)
AND NOT EXISTS (	SELECT 1
					FROM DeactivatedCustomers dc
					WHERE n.FanID = dc.FanID)

UNION

SELECT	EmailAddress
	,	FanID
	,	CIN
	,	ClubID
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
FROM DeactivatedCustomers dc

UNION

SELECT	EmailAddress
	,	FanID
	,	COALESCE((SELECT CONVERT(VARCHAR(24), LionSendID) FROM SmartEmail.OfferSlotData osd WHERE sc.FanID = osd.FanID), '') AS CIN
	,	ClubID
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

