CREATE TABLE [Relational].[CustomerJourneyV2] (
    [ID]                    INT         IDENTITY (1, 1) NOT NULL,
    [FanID]                 INT         NOT NULL,
    [CustomerJourneyStatus] VARCHAR (8) NOT NULL,
    [StartDate]             DATE        NOT NULL,
    [EndDate]               DATE        NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

