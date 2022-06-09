CREATE VIEW [ras].[FailedPANlessTransaction]
AS
SELECT 
	[FailedPANlessTransactionID]
      ,[FileID]
      ,[PartnerID]
      ,[CashbackEarned]
      ,[CommissionRate]
      ,[FailureReason]
      ,[GrossAmount]
      ,[MaskedCardNumber]
      ,[MerchantNumber]
      ,[NetAmount]
      ,[OfferCode]
      ,[OfferRate]
      ,[Price]
      ,[RewardStatus]
      ,[TransactionDate]
      ,[VATAmount]
      ,[InternalError]
      ,[RetryCount]
      ,[CreateDate]
      ,[Active]
  FROM [SLC_Snapshot].[RAS].[FailedPANlessTransaction]
GO
GRANT SELECT
    ON OBJECT::[ras].[FailedPANlessTransaction] TO [Analyst]
    AS [dbo];

