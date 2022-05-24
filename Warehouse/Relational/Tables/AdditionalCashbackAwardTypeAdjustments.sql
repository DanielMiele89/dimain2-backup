CREATE TABLE [Relational].[AdditionalCashbackAwardTypeAdjustments] (
    [ID]                                     INT     IDENTITY (1, 1) NOT NULL,
    [AdditionalCashbackAwardTypeID_Original] TINYINT NULL,
    [AdditionalCashbackAwardTypeID_New]      TINYINT NULL,
    [StartDate]                              DATE    NULL,
    [EndDate]                                DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    UNIQUE NONCLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_AdditionalCashbackAwardTypeID_Original]
    ON [Relational].[AdditionalCashbackAwardTypeAdjustments]([AdditionalCashbackAwardTypeID_Original] ASC);

