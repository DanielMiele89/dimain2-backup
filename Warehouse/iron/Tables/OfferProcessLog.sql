CREATE TABLE [iron].[OfferProcessLog] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [IsUpdate]      BIT      NOT NULL,
    [Processed]     BIT      NOT NULL,
    [ProcessedDate] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ProcessedDate_IncIronOFferID]
    ON [iron].[OfferProcessLog]([ProcessedDate] ASC)
    INCLUDE([IronOfferID]);

