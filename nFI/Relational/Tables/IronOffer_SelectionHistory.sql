CREATE TABLE [Relational].[IronOffer_SelectionHistory] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [FanID]         INT      NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [ROC_SegmentID] TINYINT  NULL,
    [isControl]     BIT      NULL,
    [PartnerID]     SMALLINT NOT NULL,
    [StartDate]     DATE     NULL,
    [EndDate]       DATE     NULL,
    [AddedDate]     DATE     NULL,
    CONSTRAINT [pk_SHI] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_F]
    ON [Relational].[IronOffer_SelectionHistory]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_I]
    ON [Relational].[IronOffer_SelectionHistory]([IronOfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_P]
    ON [Relational].[IronOffer_SelectionHistory]([PartnerID] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_R]
    ON [Relational].[IronOffer_SelectionHistory]([ROC_SegmentID] ASC);

