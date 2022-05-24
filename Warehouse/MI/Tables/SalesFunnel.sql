CREATE TABLE [MI].[SalesFunnel] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT NOT NULL,
    [Date]         DATE     NULL,
    [FunnelStatus] TINYINT  NOT NULL,
    CONSTRAINT [PK_MI_SalesFunnel] PRIMARY KEY CLUSTERED ([ID] ASC)
);

