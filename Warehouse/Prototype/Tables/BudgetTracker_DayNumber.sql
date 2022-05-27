CREATE TABLE [Prototype].[BudgetTracker_DayNumber] (
    [ID]      INT      IDENTITY (1, 1) NOT NULL,
    [DayID]   SMALLINT NOT NULL,
    [DayDate] DATE     NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

