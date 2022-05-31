CREATE TABLE [Rory].[OS_OfflineOnlyCustomers_2] (
    [FanID]                    INT            NOT NULL,
    [CompositeID]              BIGINT         NULL,
    [SourceUID]                VARCHAR (20)   NULL,
    [IssuerCustomerID]         INT            NOT NULL,
    [Email]                    NVARCHAR (100) NOT NULL,
    [EmailStructureValid]      BIT            NULL,
    [ClubID]                   INT            NULL,
    [AgeCurrent]               TINYINT        NULL,
    [IsLoyalty]                INT            NOT NULL,
    [HardbouncedEmailEvent]    INT            NOT NULL,
    [InvalidOrNoEmail]         INT            NOT NULL,
    [HardbouncedCustomerTable] INT            NOT NULL,
    [PermQuarentine]           INT            NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_FanID]
    ON [Rory].[OS_OfflineOnlyCustomers_2]([FanID] ASC);

