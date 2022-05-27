CREATE TABLE [MI].[ComboSpend] (
    [ConsumerCombinationID] INT   NOT NULL,
    [Spend]                 MONEY NOT NULL,
    CONSTRAINT [PK_MI_ComboSpend] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

