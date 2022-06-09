
CREATE VIEW [hydra].[OfferConverterAudit]
AS
SELECT [OfferConverterAuditID]
      ,[HydraOfferID]
      ,[HydraOfferGroupID]
      ,[HydraOfferGroupMemberName]
      ,[IronOfferId]
  FROM SLC_Snapshot.[hydra].[OfferConverterAudit]

GO
GRANT SELECT
    ON OBJECT::[hydra].[OfferConverterAudit] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[hydra].[OfferConverterAudit] TO [Analyst]
    AS [dbo];

