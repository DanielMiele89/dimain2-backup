CREATE TABLE [Prototype].[BudgetTracker_Investment] (
    [ID]         INT      IDENTITY (1, 1) NOT NULL,
    [BrandID]    SMALLINT NOT NULL,
    [TranDate]   DATE     NOT NULL,
    [Investment] MONEY    NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

