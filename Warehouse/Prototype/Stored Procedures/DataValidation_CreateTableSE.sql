CREATE PROCEDURE [Prototype].[DataValidation_CreateTableSE]
(
	@FileName VARCHAR(30)
)
AS
BEGIN

	 SET NOCOUNT ON

	DECLARE @TableName VARCHAR(100) = 'Sandbox.'+system_user + '.[DataValSE_' + REPLACE(@FileName, ' ', '') + ']'
	EXEC ('
		IF OBJECT_ID('''+@TableName+''') IS NOT NULL DROP TABLE '+@TableName+'
		CREATE TABLE '+@TableName+'(
			[FanID] [varchar](50) NULL,
			[ClubID] [varchar](50) NULL,
			[Email] [varchar](500) NULL,			
			[ClubCashAvailable] [varchar](50) NULL,
			[ClubCashPending] [varchar](50) NULL,		
			[IsDebit] [varchar](50) NULL,
			[IsCredit] [varchar](50) NULL,
			[LoyaltyAccount] [varchar](50) NULL,
			[IsLoyalty] [varchar](50) NULL,
			[SmartEmailSendID] [varchar](50) NULL,
			[Offer1] [varchar](50) NULL,
			[Offer2] [varchar](50) NULL,
			[Offer3] [varchar](50) NULL,
			[Offer4] [varchar](50) NULL,
			[Offer5] [varchar](50) NULL,
			[Offer6] [varchar](50) NULL,
			[Offer7] [varchar](50) NULL,
			[Offer1StartDate] [varchar](50) NULL,
			[Offer2StartDate] [varchar](50) NULL,
			[Offer3StartDate] [varchar](50) NULL,
			[Offer4StartDate] [varchar](50) NULL,
			[Offer5StartDate] [varchar](50) NULL,
			[Offer6StartDate] [varchar](50) NULL,
			[Offer7StartDate] [varchar](50) NULL,
			[Offer1EndDate] [varchar](50) NULL,
			[Offer2EndDate] [varchar](50) NULL,
			[Offer3EndDate] [varchar](50) NULL,
			[Offer4EndDate] [varchar](50) NULL,
			[Offer5EndDate] [varchar](50) NULL,
			[Offer6EndDate] [varchar](50) NULL,
			[Offer7EndDate] [varchar](50) NULL,
		) ON [PRIMARY]
	')
END