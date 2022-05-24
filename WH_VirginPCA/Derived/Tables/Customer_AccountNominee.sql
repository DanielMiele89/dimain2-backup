CREATE TABLE [Derived].[Customer_AccountNominee] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [IsNominee] BIT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

