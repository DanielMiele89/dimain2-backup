CREATE TABLE [Staging].[RF_Backup_Derived_Customer_PaymentMethodsAvailable] (
    [ID]                        INT     IDENTITY (1, 1) NOT NULL,
    [FanID]                     INT     NOT NULL,
    [PaymentMethodsAvailableID] TINYINT NOT NULL,
    [StartDate]                 DATE    NOT NULL,
    [EndDate]                   DATE    NULL
);

