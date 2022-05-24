CREATE TABLE [MI].[SalesFunnelTier] (
    [BrandID] SMALLINT NOT NULL,
    [Tier]    TINYINT  NOT NULL,
    CONSTRAINT [PK_MI_SalesFunnelTier] PRIMARY KEY CLUSTERED ([BrandID] ASC)
);

