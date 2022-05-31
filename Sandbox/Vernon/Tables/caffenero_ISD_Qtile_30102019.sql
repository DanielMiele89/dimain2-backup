CREATE TABLE [Vernon].[caffenero_ISD_Qtile_30102019] (
    [CINID]          INT             NOT NULL,
    [FanID]          INT             NOT NULL,
    [Engaged]        INT             NOT NULL,
    [total_spend]    MONEY           NULL,
    [Number_trans]   INT             NULL,
    [Pre_atv]        NUMERIC (23, 6) NULL,
    [Flag]           INT             NOT NULL,
    [Quintile_group] BIGINT          NULL
);

