CREATE TABLE [Staging].[PartnerControlgroupIDs_RBSG] (
    [PartnerID] SMALLINT     NULL,
    [Segment]   VARCHAR (10) NOT NULL,
    [RowNo]     BIGINT       NULL,
    [StartDate] DATETIME     NULL,
    [EndDate]   DATETIME     NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerControlgroupIDs_RBSG]
    ON [Staging].[PartnerControlgroupIDs_RBSG]([PartnerID] ASC, [Segment] ASC);


GO
CREATE UNIQUE CLUSTERED INDEX [UCIX_PartnerControlgroupIDs_RBSG]
    ON [Staging].[PartnerControlgroupIDs_RBSG]([PartnerID] ASC, [RowNo] ASC, [StartDate] ASC, [EndDate] ASC);

