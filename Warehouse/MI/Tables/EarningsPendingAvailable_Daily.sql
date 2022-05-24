CREATE TABLE [MI].[EarningsPendingAvailable_Daily] (
    [ID]                INT   IDENTITY (1, 1) NOT NULL,
    [EarningsDate]      DATE  NOT NULL,
    [EarningsPending]   MONEY NOT NULL,
    [EarningsAvailable] MONEY NOT NULL,
    CONSTRAINT [PK_MI_EarningsPendingAvailable_Daily] PRIMARY KEY CLUSTERED ([ID] ASC)
);

