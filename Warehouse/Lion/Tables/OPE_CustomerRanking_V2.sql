CREATE TABLE [Lion].[OPE_CustomerRanking_V2] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]       SMALLINT NULL,
    [FanID]           INT      NULL,
    [CompositeID]     BIGINT   NULL,
    [Segment]         TINYINT  NULL,
    [CustomerRanking] SMALLINT NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerComp_IncSegRank]
    ON [Lion].[OPE_CustomerRanking_V2]([PartnerID] ASC, [CompositeID] ASC)
    INCLUDE([Segment], [CustomerRanking]);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_PartnerFan]
    ON [Lion].[OPE_CustomerRanking_V2]([ID] ASC, [PartnerID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Lion].[OPE_CustomerRanking_V2]([PartnerID], [Segment], [FanID], [CompositeID], [CustomerRanking]);

