CREATE TABLE [MI].[SalesFunnel_Holding] (
    [ID]           INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]      SMALLINT NOT NULL,
    [Date]         DATE     NULL,
    [FunnelStatus] TINYINT  NOT NULL,
    CONSTRAINT [PK_MI_SalesFunnel_Holding] PRIMARY KEY CLUSTERED ([ID] ASC)
);

