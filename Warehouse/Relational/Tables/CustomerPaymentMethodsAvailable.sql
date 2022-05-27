CREATE TABLE [Relational].[CustomerPaymentMethodsAvailable] (
    [CustomerPaymentMethodsAvailableID] INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                             INT     NOT NULL,
    [PaymentMethodsAvailableID]         TINYINT NOT NULL,
    [StartDate]                         DATE    NOT NULL,
    [EndDate]                           DATE    NULL,
    PRIMARY KEY CLUSTERED ([CustomerPaymentMethodsAvailableID] ASC)
);

