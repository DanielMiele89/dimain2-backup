CREATE TABLE [MI].[ConsumerCombination_Created] (
    [ConsumerCombinationID] INT  NOT NULL,
    [CreateDate]            DATE CONSTRAINT [DF_MI_ConsumerCombination_Created] DEFAULT (getdate()) NOT NULL,
    [CheckDate]             DATE NULL,
    CONSTRAINT [PK_MI_ConsumerCombination_Created] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE)
);

