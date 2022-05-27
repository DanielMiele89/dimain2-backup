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


GO
GRANT VIEW DEFINITION
    ON OBJECT::[iron].[OfferProcessLog] TO [gas]
    AS [dbo];


GO
GRANT VIEW CHANGE TRACKING
    ON OBJECT::[iron].[OfferProcessLog] TO [gas]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[iron].[OfferProcessLog] TO [gas]
    AS [dbo];

