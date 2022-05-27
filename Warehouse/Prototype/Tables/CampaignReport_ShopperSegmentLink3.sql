CREATE TABLE [Prototype].[CampaignReport_ShopperSegmentLink3] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [TopLevelOffer]    INT           NOT NULL,
    [BottomLevelOffer] INT           NULL,
    [nFI]              BIT           NOT NULL,
    [AlternateName]    NVARCHAR (30) NULL
);

