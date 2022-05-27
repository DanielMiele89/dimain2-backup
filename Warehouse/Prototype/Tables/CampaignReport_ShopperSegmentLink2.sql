CREATE TABLE [Prototype].[CampaignReport_ShopperSegmentLink2] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [TopLevelOffer]    INT           NOT NULL,
    [BottomLevelOffer] INT           NULL,
    [nFI]              BIT           DEFAULT ((0)) NOT NULL,
    [AlternateName]    NVARCHAR (30) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

