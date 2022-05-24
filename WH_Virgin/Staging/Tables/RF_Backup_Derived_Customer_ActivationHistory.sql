CREATE TABLE [Staging].[RF_Backup_Derived_Customer_ActivationHistory] (
    [ID]              INT  IDENTITY (1, 1) NOT NULL,
    [FanID]           INT  NOT NULL,
    [ActivatedDate]   DATE NOT NULL,
    [DeactivatedDate] DATE NULL
);

