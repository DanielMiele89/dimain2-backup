CREATE TABLE [Selections].[CampaignExecution_CustomerBase] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT           NOT NULL,
    [ShopperSegmentTypeID] SMALLINT      NOT NULL,
    [FanID]                INT           NOT NULL,
    [CompositeID]          BIGINT        NULL,
    [Postcode]             VARCHAR (100) NULL,
    [ActivatedDate]        DATE          NULL,
    [Gender]               CHAR (1)      NULL,
    [MarketableByEmail]    BIT           NULL,
    [DOB]                  DATE          NULL,
    [AgeCurrent]           TINYINT       NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Selections].[CampaignExecution_CustomerBase]([PartnerID], [CompositeID], [ShopperSegmentTypeID], [ActivatedDate], [Gender], [AgeCurrent], [DOB], [MarketableByEmail]);

