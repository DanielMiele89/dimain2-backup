
CREATE VIEW [hydra].[PublisherLink]
AS
SELECT [PublisherLinkID]
      ,[HydraPublisherID]
      ,[ClubID]
  FROM SLC_Snapshot.[hydra].[PublisherLink]

GO
GRANT SELECT
    ON OBJECT::[hydra].[PublisherLink] TO [Analyst]
    AS [dbo];

