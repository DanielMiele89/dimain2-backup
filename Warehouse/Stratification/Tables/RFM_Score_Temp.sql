CREATE TABLE [Stratification].[RFM_Score_Temp] (
    [CINID]             INT          NULL,
    [Activated]         INT          NOT NULL,
    [LastRetailDate]    DATE         NULL,
    [BigRetail_Recency] INT          NULL,
    [BigRetail_Spend]   MONEY        NOT NULL,
    [BigRetail_Txns]    FLOAT (53)   NOT NULL,
    [Recency_Score]     INT          NULL,
    [Monetary_Score]    BIGINT       NULL,
    [Frequency_Score]   BIGINT       NULL,
    [RFM_Score]         BIGINT       NULL,
    [RFM_group]         VARCHAR (16) NULL
);

