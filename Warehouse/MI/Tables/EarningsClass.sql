CREATE TABLE [MI].[EarningsClass] (
    [ID]            TINYINT      IDENTITY (1, 1) NOT NULL,
    [EarningsClass] VARCHAR (50) NOT NULL,
    [MinValue]      MONEY        NOT NULL,
    [MaxValue]      MONEY        NOT NULL,
    CONSTRAINT [PK_MI_EarningsClass] PRIMARY KEY CLUSTERED ([ID] ASC)
);

