CREATE VIEW [dbo].BankAccountTypeEligibility
AS
SELECT  [ID]
      ,[IssuerID]
      ,[BankAccountType]
      ,[CustomerSegment]
      ,[DirectDebitEligible]
      ,[POSEligible]
      ,[IronOfferID]
      ,[Priority]
      ,[AutoActivateCBPAccount]
      ,[LoyaltyFlag]
  FROM SLC_Snapshot.[dbo].[BankAccountTypeEligibility]