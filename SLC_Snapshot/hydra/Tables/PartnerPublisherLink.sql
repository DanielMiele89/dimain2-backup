CREATE TABLE [hydra].[PartnerPublisherLink] (
    [PartnerPublisherLinkID] UNIQUEIDENTIFIER NOT NULL,
    [HydraPartnerID]         UNIQUEIDENTIFIER NOT NULL,
    [HydraPublisherID]       UNIQUEIDENTIFIER NOT NULL,
    [PartnerID]              INT              NOT NULL,
    CONSTRAINT [PK_PartnerPublisherLink] PRIMARY KEY CLUSTERED ([PartnerPublisherLinkID] ASC),
    CONSTRAINT [UC_PartnerPublisherLink] UNIQUE NONCLUSTERED ([HydraPublisherID] ASC, [HydraPartnerID] ASC, [PartnerID] ASC)
);


GO
GRANT SELECT
    ON [hydra].[PartnerPublisherLink] ([PartnerID]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[hydra].[PartnerPublisherLink] TO [virgin_etl_user]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[hydra].[PartnerPublisherLink] TO [visa_etl_user]
    AS [dbo];

