CREATE TABLE [iron].[OfferProcessLog_Archive] (
    [ID]            INT      NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [IsUpdate]      BIT      NOT NULL,
    [Processed]     BIT      NOT NULL,
    [ProcessedDate] DATETIME NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

