CREATE TABLE [Selections].[OfferProcessLog_20191203] (
    [ID]            INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]   INT      NOT NULL,
    [IsUpdate]      BIT      NOT NULL,
    [Processed]     BIT      NOT NULL,
    [ProcessedDate] DATETIME NULL
);

