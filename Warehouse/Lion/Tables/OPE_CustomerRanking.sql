CREATE TABLE [Lion].[OPE_CustomerRanking] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]       INT          NULL,
    [IsPOS]           BIT          NULL,
    [IsDD]            BIT          NULL,
    [FanID]           BIGINT       NULL,
    [CompositeID]     BIGINT       NULL,
    [Segment]         VARCHAR (20) NULL,
    [CustomerRanking] BIGINT       NULL
);


GO
CREATE NONCLUSTERED INDEX [IX_PartnerComp_IncSegRank]
    ON [Lion].[OPE_CustomerRanking]([PartnerID] ASC, [CompositeID] ASC)
    INCLUDE([Segment], [CustomerRanking]);


GO
CREATE CLUSTERED INDEX [CIX_All]
    ON [Lion].[OPE_CustomerRanking]([PartnerID] ASC, [Segment] ASC, [FanID] ASC, [CompositeID] ASC, [CustomerRanking] ASC) WITH (FILLFACTOR = 90);

