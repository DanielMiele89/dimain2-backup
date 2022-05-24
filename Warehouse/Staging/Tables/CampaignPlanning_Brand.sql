CREATE TABLE [Staging].[CampaignPlanning_Brand] (
    [RowNo]          SMALLINT      NOT NULL,
    [PartnerID]      SMALLINT      NOT NULL,
    [BrandID]        SMALLINT      NOT NULL,
    [BrandName]      VARCHAR (100) NULL,
    [Halo]           FLOAT (53)    NULL,
    [Margin]         FLOAT (53)    NULL,
    [Override]       FLOAT (53)    NULL,
    [BaseOffer]      FLOAT (53)    NULL,
    [RetailerTypeID] TINYINT       NULL,
    [isLive]         BIT           DEFAULT ((0)) NOT NULL,
    [RetailerClass]  VARCHAR (20)  NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_R]
    ON [Staging].[CampaignPlanning_Brand]([RowNo] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_B]
    ON [Staging].[CampaignPlanning_Brand]([BrandID] ASC);

