CREATE TABLE [Selections].[PrioritisedCustomerAccounts] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [FanID]       INT           NOT NULL,
    [CompositeID] BIGINT        NULL,
    [FirstName]   VARCHAR (50)  NULL,
    [LastName]    VARCHAR (50)  NULL,
    [Email]       VARCHAR (100) NULL,
    [StartDate]   DATE          NOT NULL,
    [EndDate]     DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC) WITH (FILLFACTOR = 90)
);

