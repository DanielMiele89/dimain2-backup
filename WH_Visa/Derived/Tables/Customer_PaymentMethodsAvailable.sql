CREATE TABLE [Derived].[Customer_PaymentMethodsAvailable] (
    [ID]                        INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                     INT     NOT NULL,
    [PaymentMethodsAvailableID] TINYINT NOT NULL,
    [StartDate]                 DATE    NOT NULL,
    [EndDate]                   DATE    NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

