CREATE TABLE [Relational].[RedemptionCodesRollup] (
    [ID]                  INT     IDENTITY (1, 1) NOT NULL,
    [CodeTypeID_Original] INT     NOT NULL,
    [CodeType_RollUp]     INT     NOT NULL,
    [Multiplier]          TINYINT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

