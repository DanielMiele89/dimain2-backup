CREATE TABLE [InsightArchive].[Shopper_pack_lapsed] (
    [main_brand]        VARCHAR (50) NULL,
    [cinid]             INT          NOT NULL,
    [prior_spend]       MONEY        NULL,
    [prior_trans]       INT          NULL,
    [prior_total_spend] MONEY        NULL,
    [recent_spend]      MONEY        NULL,
    [recent_trans]      INT          NULL
);

