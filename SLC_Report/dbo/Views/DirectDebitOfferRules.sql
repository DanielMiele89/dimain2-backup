



CREATE VIEW [dbo].[DirectDebitOfferRules]
AS
SELECT [ID]
      ,[IronOfferID]
      ,[MinimumSpend]
      ,[FixedReward]
      ,[RewardAmount]
      ,[RewardPercent]
      ,[BillingAmount]
      ,[BillingPercent]
FROM SLC_Snapshot.dbo.DirectDebitOfferRules


GO
GRANT SELECT
    ON OBJECT::[dbo].[DirectDebitOfferRules] TO [virgin_etl_user]
    AS [dbo];

