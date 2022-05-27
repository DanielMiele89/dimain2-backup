CREATE TABLE [MI].[MOMCombinationLastTrans] (
    [ConsumerCombinationID] INT  NOT NULL,
    [LastTranDate]          DATE NOT NULL,
    CONSTRAINT [PK_MI_MOMCombinationLastTrans] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);

