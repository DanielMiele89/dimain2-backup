CREATE TABLE [Staging].[R_0061_Merchant_MID_Checker] (
    [MID]                   VARCHAR (50) NOT NULL,
    [ConsumerCombinationID] INT          NOT NULL,
    [Narrative]             VARCHAR (50) NOT NULL,
    [LocationCountry]       VARCHAR (3)  NOT NULL,
    [FirstTran]             DATE         NULL,
    [LastTran]              DATE         NULL,
    [Trans]                 INT          NULL,
    [OnlineTrans]           INT          NULL,
    [OfflineTrans]          INT          NULL
);

