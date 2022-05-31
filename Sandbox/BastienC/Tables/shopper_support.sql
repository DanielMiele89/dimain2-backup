CREATE TABLE [BastienC].[shopper_support] (
    [main_brand]        VARCHAR (50) NULL,
    [cinid]             INT          NOT NULL,
    [MONTH_commencing]  DATETIME     NULL,
    [prior_spend]       MONEY        NULL,
    [prior_trans]       INT          NULL,
    [prior_total_spend] MONEY        NULL,
    [lapsed_flag]       INT          NULL,
    [sow]               MONEY        NULL
);

