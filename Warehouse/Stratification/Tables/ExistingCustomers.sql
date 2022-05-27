CREATE TABLE [Stratification].[ExistingCustomers] (
    [partnergroupid]    INT          NULL,
    [partnerid]         INT          NULL,
    [fanid]             INT          NOT NULL,
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [CustType]          CHAR (1)     NULL,
    [MinMonthID]        INT          NULL,
    [MaxMonthID]        INT          NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    CONSTRAINT [PK_Stratification_ExistingCustomers] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [dw_fanid_ec]
    ON [Stratification].[ExistingCustomers]([fanid] ASC);


GO
CREATE NONCLUSTERED INDEX [dw_fanid_partnergroup]
    ON [Stratification].[ExistingCustomers]([partnergroupid] ASC);

