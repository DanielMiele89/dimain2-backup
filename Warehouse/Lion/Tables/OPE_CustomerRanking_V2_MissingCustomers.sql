CREATE TABLE [Lion].[OPE_CustomerRanking_V2_MissingCustomers] (
    [ID]              INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]       SMALLINT NULL,
    [FanID]           INT      NULL,
    [CompositeID]     BIGINT   NULL,
    [Segment]         TINYINT  NULL,
    [CustomerRanking] SMALLINT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [UCX_PartnerFan]
    ON [Lion].[OPE_CustomerRanking_V2_MissingCustomers]([ID] ASC, [PartnerID] ASC, [FanID] ASC) WITH (FILLFACTOR = 90);


GO
CREATE COLUMNSTORE INDEX [CSX_All]
    ON [Lion].[OPE_CustomerRanking_V2_MissingCustomers]([PartnerID], [Segment], [FanID], [CompositeID], [CustomerRanking]);

