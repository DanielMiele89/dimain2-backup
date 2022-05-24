CREATE TABLE [Stratification].[ActivatedCustomers_Temp] (
    [PartnerID]         INT          NULL,
    [ReportMonth]       INT          NOT NULL,
    [CINID]             INT          NULL,
    [FanID]             INT          NULL,
    [CompositeID]       BIGINT       NULL,
    [Activated]         INT          NOT NULL,
    [IsRainbow]         INT          NOT NULL,
    [PartnerIDType]     VARCHAR (50) NOT NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    CONSTRAINT [u1] UNIQUE NONCLUSTERED ([FanID] ASC, [PartnerID] ASC, [ClientServicesRef] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_PartnerID]
    ON [Stratification].[ActivatedCustomers_Temp]([PartnerID] ASC);


GO
CREATE CLUSTERED INDEX [IND_FanID]
    ON [Stratification].[ActivatedCustomers_Temp]([FanID] ASC);

