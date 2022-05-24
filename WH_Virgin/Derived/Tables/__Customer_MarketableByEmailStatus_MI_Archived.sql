CREATE TABLE [Derived].[__Customer_MarketableByEmailStatus_MI_Archived] (
    [ID]           INT     IDENTITY (1, 1) NOT NULL,
    [FanID]        INT     NOT NULL,
    [MarketableID] TINYINT NOT NULL,
    [StartDate]    DATE    NOT NULL,
    [EndDate]      DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

