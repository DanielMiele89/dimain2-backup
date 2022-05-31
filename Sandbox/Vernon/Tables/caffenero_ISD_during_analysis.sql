CREATE TABLE [Vernon].[caffenero_ISD_during_analysis] (
    [CINID]          INT             NOT NULL,
    [FanID]          INT             NOT NULL,
    [Engaged]        INT             NOT NULL,
    [total_spend]    MONEY           NULL,
    [Number_trans]   INT             NULL,
    [Pre_atv]        NUMERIC (23, 6) NULL,
    [Flag]           INT             NOT NULL,
    [Quintile_group] BIGINT          NULL,
    [during_spend]   MONEY           NULL,
    [during_trans]   INT             NULL,
    [During_ATV]     NUMERIC (23, 6) NULL,
    [IronOfferID]    INT             NULL,
    [Costofcashback] MONEY           NULL,
    [cashbackearned] MONEY           NULL,
    [MinSeenDate]    DATE            NULL
);

