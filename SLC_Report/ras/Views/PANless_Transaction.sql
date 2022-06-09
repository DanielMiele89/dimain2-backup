


CREATE VIEW [ras].[PANless_Transaction]
AS
SELECT [ID]
      ,[FileID]
      ,[PartnerID]
      ,[InvoiceID]
      ,[TransactionDate]
      ,[OfferCode]
      ,[OfferRate]
      ,[CashbackEarned]
      ,[CommissionRate]
      ,[NetAmount]
      ,[VATAmount]
      ,[GrossAmount]
      ,[MaskedCardNumber]
      ,[VATRate]
      ,[Price]
      ,[MerchantNumber]
	  ,CustomerID
	  ,PublisherOfferCode
	  ,[FailedPANlessTransactionID]
	  ,[AddedDate]
FROM SLC_Snapshot.[RAS].[PANless_Transaction]

GO
GRANT SELECT
    ON OBJECT::[ras].[PANless_Transaction] TO [Analyst]
    AS [dbo];

