CREATE TABLE [Derived].[__DeactivatedCustomers_Archived] (
    [FanID]         INT      NOT NULL,
    [Status]        INT      NOT NULL,
    [AgreedTCs]     BIT      NULL,
    [AgreedTCsDate] DATETIME NULL,
    [DataDate]      DATE     NULL,
    [LoadedDate]    DATE     NULL
);


GO
CREATE CLUSTERED INDEX [cx_DC]
    ON [Derived].[__DeactivatedCustomers_Archived]([FanID] ASC, [LoadedDate] ASC);

