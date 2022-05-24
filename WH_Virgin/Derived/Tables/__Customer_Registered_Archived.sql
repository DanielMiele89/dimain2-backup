CREATE TABLE [Derived].[__Customer_Registered_Archived] (
    [ID]         INT  IDENTITY (1, 1) NOT NULL,
    [FanID]      INT  NOT NULL,
    [Registered] BIT  NOT NULL,
    [StartDate]  DATE NOT NULL,
    [EndDate]    DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

