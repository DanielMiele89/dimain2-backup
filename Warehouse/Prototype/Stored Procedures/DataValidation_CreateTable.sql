CREATE PROCEDURE [Prototype].[DataValidation_CreateTable]
(
	@FileName VARCHAR(30)
)
AS
BEGIN

	 SET NOCOUNT ON

	DECLARE @TableName VARCHAR(100) = 'Sandbox.'+system_user + '.[DataVal_' + REPLACE(@FileName, ' ', '') + ']'
	EXEC ('
		IF OBJECT_ID('''+@TableName+''') IS NOT NULL DROP TABLE '+@TableName+'
		CREATE TABLE '+@TableName+'(
			[AgreedTcsDate] [varchar](50) NULL,
			[ClubCashAvailable] [varchar](50) NULL,
			[ClubCashPending] [varchar](50) NULL,
			[ClubID] [varchar](50) NULL,
			[customer id] [varchar](50) NULL,
			[Email] [varchar](500) NULL,
			[IsCharity] [varchar](50) NULL,
			[IsCredit] [varchar](50) NULL,
			[IsDebit] [varchar](50) NULL,
			[IsLoyalty] [varchar](50) NULL,
			[LionSendID] [varchar](50) NULL,
			[LoyaltyAccount] [varchar](50) NULL,
			[Nominee] [varchar](50) NULL,
			[Offer1] [varchar](50) NULL,
			[Offer2] [varchar](50) NULL,
			[Offer3] [varchar](50) NULL,
			[Offer4] [varchar](50) NULL,
			[Offer5] [varchar](50) NULL,
			[Offer6] [varchar](50) NULL,
			[Offer7] [varchar](50) NULL,
			[Reached5GBP] [varchar](50) NULL,
			[RewardAccountName] [varchar](50) NULL,
			[WG] [varchar](50) NULL
		) ON [PRIMARY]
	')
END