
CREATE VIEW [hydra].[PartnerPublisherLink]
AS
SELECT [PartnerPublisherLinkID]
      ,[HydraPartnerID]
      ,[HydraPublisherID]
      ,[PartnerID]
  FROM SLC_Snapshot.[hydra].[PartnerPublisherLink]

GO
GRANT SELECT
    ON OBJECT::[hydra].[PartnerPublisherLink] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[hydra].[PartnerPublisherLink] TO [Analyst]
    AS [dbo];

