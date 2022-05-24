CREATE TABLE [Selections].[CampaignCode_Selections_Selection] (
    [FanID]                BIGINT       NULL,
    [CompositeID]          BIGINT       NULL,
    [ShopperSegmentTypeID] INT          NULL,
    [SOWCategory]          VARCHAR (1)  NULL,
    [PartnerID]            INT          NULL,
    [PartnerName]          VARCHAR (50) NULL,
    [OfferID]              INT          NULL,
    [ClientServicesRef]    VARCHAR (10) NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [Ranking]              INT          NULL,
    [RowNumber]            INT          NULL,
    [RowNumberInsert]      INT          NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber]
    ON [Selections].[CampaignCode_Selections_Selection]([OfferID] ASC, [CompositeID] ASC)
    INCLUDE([RowNumber]);


GO
ALTER INDEX [IX_CampaignCodeSelectionsSelection_OfferIDCompositeIDRowNumber]
    ON [Selections].[CampaignCode_Selections_Selection] DISABLE;


GO
CREATE NONCLUSTERED INDEX [IX_CampaignCodeSelectionsSelection_OfferIDRowNumberInsert]
    ON [Selections].[CampaignCode_Selections_Selection]([OfferID] ASC, [RowNumberInsert] ASC);


GO
CREATE CLUSTERED INDEX [CIX_CampaignCodeSelectionsSelection_CompositeID]
    ON [Selections].[CampaignCode_Selections_Selection]([CompositeID] ASC);

