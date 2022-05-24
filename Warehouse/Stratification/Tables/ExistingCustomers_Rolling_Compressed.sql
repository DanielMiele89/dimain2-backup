CREATE TABLE [Stratification].[ExistingCustomers_Rolling_Compressed] (
    [MinMonthID]        INT          NOT NULL,
    [MaxMonthID]        INT          NOT NULL,
    [partnergroupid]    INT          NULL,
    [partnerid]         INT          NULL,
    [fanid]             INT          NOT NULL,
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [CustType]          CHAR (1)     NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [DW_EC_UR2] UNIQUE NONCLUSTERED ([partnergroupid] ASC, [partnerid] ASC, [fanid] ASC, [MinMonthID] ASC, [ClientServicesRef] ASC) WITH (DATA_COMPRESSION = PAGE) ON [Warehouse_Indexes]
);


GO
CREATE NONCLUSTERED INDEX [dw_fanid_ec]
    ON [Stratification].[ExistingCustomers_Rolling_Compressed]([fanid] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [dw_fanid_partner]
    ON [Stratification].[ExistingCustomers_Rolling_Compressed]([partnerid] ASC) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

