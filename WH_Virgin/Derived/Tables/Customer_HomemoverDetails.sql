CREATE TABLE [Derived].[Customer_HomemoverDetails] (
    [ID]          INT          IDENTITY (1, 1) NOT NULL,
    [FanID]       INT          NOT NULL,
    [OldPostCode] VARCHAR (64) NOT NULL,
    [NewPostCode] VARCHAR (64) NOT NULL,
    [LoadDate]    DATE         NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

