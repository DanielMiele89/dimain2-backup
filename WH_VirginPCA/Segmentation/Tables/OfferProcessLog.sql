CREATE TABLE [Segmentation].[OfferProcessLog] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [IsUpdate]      BIT      NOT NULL,
    [SignedOff]     BIT      NOT NULL,
    [Processed]     BIT      NOT NULL,
    [ProcessedDate] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_OfferSignedOffProcessed]
    ON [Segmentation].[OfferProcessLog]([IronOfferID] ASC, [SignedOff] ASC, [Processed] ASC)
    INCLUDE([IsUpdate]);

