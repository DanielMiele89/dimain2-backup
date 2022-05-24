CREATE TABLE [Staging].[RF_Backup_Derived_DeactivatedCustomers] (
    [FanID]         INT      NOT NULL,
    [Status]        INT      NOT NULL,
    [AgreedTCs]     BIT      NULL,
    [AgreedTCsDate] DATETIME NULL,
    [DataDate]      DATE     NULL,
    [LoadedDate]    DATE     NULL
);

