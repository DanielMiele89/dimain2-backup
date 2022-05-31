CREATE TABLE [SamW].[OPE_CustomerRanking] (
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]       INT          NULL,
    [IsPOS]           BIT          NULL,
    [IsDD]            BIT          NULL,
    [FanID]           BIGINT       NULL,
    [CompositeID]     BIGINT       NULL,
    [Segment]         VARCHAR (20) NULL,
    [CustomerRanking] BIGINT       NULL
);

