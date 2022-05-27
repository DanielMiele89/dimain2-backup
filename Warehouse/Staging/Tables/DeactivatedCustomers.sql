CREATE TABLE [Staging].[DeactivatedCustomers] (
    [FanID]         INT      NOT NULL,
    [Status]        INT      NOT NULL,
    [AgreedTCs]     BIT      NULL,
    [AgreedTCsDate] DATETIME NULL,
    [DataDate]      DATE     NULL,
    [LoadedDate]    DATE     NULL
);


GO
CREATE CLUSTERED INDEX [cx_FanID_DataDate]
    ON [Staging].[DeactivatedCustomers]([FanID] ASC, [DataDate] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [ix_LoadedDate]
    ON [Staging].[DeactivatedCustomers]([LoadedDate] ASC) WITH (FILLFACTOR = 95, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

