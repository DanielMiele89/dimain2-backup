CREATE TABLE [APW].[MarketShareCombination] (
    [ConsumerCombinationID] INT NOT NULL,
    [IsRetailer]            BIT NOT NULL,
    CONSTRAINT [PK_APW_MarketShareCombination] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

