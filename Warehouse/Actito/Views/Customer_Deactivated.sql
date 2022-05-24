
CREATE VIEW [Actito].[Customer_Deactivated] 
AS

WITH
DeactivatedCustomers AS (	SELECT	EmailAddress = CAST('MyRewardsClosedAccount@RewardInsight.com' AS NVARCHAR(255))
								,	FanID = v.[FanID]
								,	CIN = ''
								,	ClubID = 0
							--	,	[ClubName]
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
							FROM [Warehouse].[Relational].[Customer] v
							WHERE v.CurrentlyActive = 0
							AND EXISTS (SELECT 1
										FROM [Warehouse].[SmartEmail].[DataVal_BurnOffer] bo
										WHERE v.FanID = bo.FanID_Offer))

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

