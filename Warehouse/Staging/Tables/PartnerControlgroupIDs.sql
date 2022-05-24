CREATE TABLE [Staging].[PartnerControlgroupIDs] (
    [PartnerID] SMALLINT     NULL,
    [Segment]   VARCHAR (10) NOT NULL,
    [RowNo]     BIGINT       NULL,
    [StartDate] DATETIME     NULL,
    [EndDate]   DATETIME     NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerControlgroupIDs]
    ON [Staging].[PartnerControlgroupIDs]([PartnerID] ASC, [Segment] ASC);


GO
CREATE UNIQUE CLUSTERED INDEX [UCIX_PartnerControlgroupIDs]
    ON [Staging].[PartnerControlgroupIDs]([RowNo] ASC, [StartDate] ASC, [EndDate] ASC);

