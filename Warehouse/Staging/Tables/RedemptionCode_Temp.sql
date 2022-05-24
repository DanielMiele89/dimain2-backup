CREATE TABLE [Staging].[RedemptionCode_Temp] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [Code]                 VARCHAR (40) NOT NULL,
    [FanID]                INT          NULL,
    [BatchID]              SMALLINT     NOT NULL,
    [MembersAssignedBatch] SMALLINT     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

