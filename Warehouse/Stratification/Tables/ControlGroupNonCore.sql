CREATE TABLE [Stratification].[ControlGroupNonCore] (
    [ClientServicesRef] VARCHAR (40) NULL,
    [PartnerID]         INT          NULL,
    [FanID]             INT          NULL,
    [CINID]             INT          NULL
);


GO
CREATE CLUSTERED INDEX [FANINX]
    ON [Stratification].[ControlGroupNonCore]([FanID] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [PARTNERINX]
    ON [Stratification].[ControlGroupNonCore]([PartnerID] ASC);

