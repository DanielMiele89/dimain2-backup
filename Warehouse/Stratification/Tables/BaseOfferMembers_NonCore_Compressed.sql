CREATE TABLE [Stratification].[BaseOfferMembers_NonCore_Compressed] (
    [id]                INT          IDENTITY (1, 1) NOT NULL,
    [CinID]             INT          NULL,
    [FanID]             INT          NULL,
    [PartnerID]         INT          NULL,
    [MinMonthID]        INT          NOT NULL,
    [MaxMonthID]        INT          NOT NULL,
    [PartnerGroupID]    INT          NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    CONSTRAINT [PK_Stratification_BaseOfferMembers_NonCore_Compressed] PRIMARY KEY CLUSTERED ([id] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [UNQ_Stratification_BaseOfferMembers_NonCore_Compressed] UNIQUE NONCLUSTERED ([FanID] ASC, [PartnerID] ASC, [MinMonthID] ASC, [ClientServicesRef] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_BaseOfferMembers_NonCore_Compressed_MonthIDs]
    ON [Stratification].[BaseOfferMembers_NonCore_Compressed]([MinMonthID] ASC, [MaxMonthID] ASC)
    INCLUDE([FanID], [PartnerID], [ClientServicesRef]) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_RVW_Stratification_BaseOfferMembers_NonCore_Compressed_PartnerMonthIDs]
    ON [Stratification].[BaseOfferMembers_NonCore_Compressed]([PartnerID] ASC, [MinMonthID] ASC, [MaxMonthID] ASC)
    INCLUDE([FanID], [ClientServicesRef]) WITH (DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

