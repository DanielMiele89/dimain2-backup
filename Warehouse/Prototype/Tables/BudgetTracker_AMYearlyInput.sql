CREATE TABLE [Prototype].[BudgetTracker_AMYearlyInput] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]        SMALLINT     NOT NULL,
    [BrandName]      VARCHAR (50) NOT NULL,
    [AccountManager] VARCHAR (50) NOT NULL,
    [StartDate]      DATE         NOT NULL,
    [EndDate]        DATE         NOT NULL,
    [Budget]         MONEY        NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

