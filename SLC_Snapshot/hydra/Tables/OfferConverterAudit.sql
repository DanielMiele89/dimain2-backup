CREATE TABLE [hydra].[OfferConverterAudit] (
    [OfferConverterAuditID]     UNIQUEIDENTIFIER NOT NULL,
    [HydraOfferID]              UNIQUEIDENTIFIER NOT NULL,
    [HydraOfferGroupID]         UNIQUEIDENTIFIER NOT NULL,
    [HydraOfferGroupMemberName] NVARCHAR (100)   NOT NULL,
    [IronOfferId]               INT              NOT NULL,
    CONSTRAINT [PK_OfferConverterAudit] PRIMARY KEY CLUSTERED ([OfferConverterAuditID] ASC)
);


GO
GRANT SELECT
    ON OBJECT::[hydra].[OfferConverterAudit] TO [virgin_etl_user]
    AS [dbo];

