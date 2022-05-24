CREATE TABLE [MI].[BrandDetection] (
    [ConsumerCombinationID] INT   NOT NULL,
    [Spend]                 MONEY NOT NULL,
    [StartOfMonth]          DATE  NOT NULL,
    CONSTRAINT [PK_MI_BrandDetection] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC, [StartOfMonth] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

