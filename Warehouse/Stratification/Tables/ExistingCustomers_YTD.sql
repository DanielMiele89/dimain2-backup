CREATE TABLE [Stratification].[ExistingCustomers_YTD] (
    [partnergroupid]    INT          NULL,
    [partnerid]         INT          NULL,
    [fanid]             INT          NOT NULL,
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [CustType]          CHAR (1)     NULL,
    [MinMonthID]        INT          NULL,
    [MaxMonthID]        INT          NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    CONSTRAINT [PK_Stratification_ExistingCustomers_YTD] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [DW_EC_U2] UNIQUE NONCLUSTERED ([partnergroupid] ASC, [partnerid] ASC, [fanid] ASC, [ClientServicesRef] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_ExistingCustomers_YTD_PartnerID]
    ON [Stratification].[ExistingCustomers_YTD]([partnerid] ASC, [fanid] ASC, [ClientServicesRef] ASC, [MinMonthID] ASC, [MaxMonthID] ASC)
    INCLUDE([CustType]);


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_ExistingCustomers_YTD]
    ON [Stratification].[ExistingCustomers_YTD]([MinMonthID] ASC, [MaxMonthID] ASC)
    INCLUDE([partnerid], [fanid], [CustType], [ClientServicesRef]);

