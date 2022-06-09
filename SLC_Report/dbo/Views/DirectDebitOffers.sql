

CREATE VIEW [dbo].[DirectDebitOffers]
AS
SELECT [IronOfferID]
      ,[EarnOnDDCount]
      ,[MaximumEarningsCount]
      ,[MinimumFirstDDDelay]
      ,[MaximumFirstDDDelay]
      ,[MaximumEarningDDDelay]
      ,[ActivationDays]
FROM SLC_Snapshot.dbo.DirectDebitOffers
GO
GRANT SELECT
    ON OBJECT::[dbo].[DirectDebitOffers] TO [virgin_etl_user]
    AS [dbo];

