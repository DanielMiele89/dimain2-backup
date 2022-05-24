CREATE TABLE [MI].[EarningsByClass_Daily] (
    [ID]              INT     IDENTITY (1, 1) NOT NULL,
    [EarningsDate]    DATE    NOT NULL,
    [EarningsClassID] TINYINT NOT NULL,
    [CustomerCount]   INT     NOT NULL,
    CONSTRAINT [PK_MI_EarningsByClass_Daily] PRIMARY KEY CLUSTERED ([ID] ASC)
);

