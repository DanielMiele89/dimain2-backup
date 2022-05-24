CREATE TABLE [Email].[OPE_CustomerRanking] (
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
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Email].[OPE_CustomerRanking]([PartnerID], [Segment], [FanID], [CompositeID], [CustomerRanking]);

