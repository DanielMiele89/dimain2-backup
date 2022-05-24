CREATE TABLE [Derived].[Customer_ActivationHistory] (
    [ID]         INT          IDENTITY (1, 1) NOT NULL,
    [FanID]      INT          NOT NULL,
    [ActionDate] DATE         NOT NULL,
    [ActionType] VARCHAR (15) NULL
);

