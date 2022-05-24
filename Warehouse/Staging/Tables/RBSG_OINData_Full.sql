CREATE TABLE [Staging].[RBSG_OINData_Full] (
    [OIN]               INT            NOT NULL,
    [ORG_OFFICIAL_NAME] NVARCHAR (255) NULL,
    [CATEGORY1]         NVARCHAR (255) NULL,
    [CATEGORY2]         NVARCHAR (255) NULL,
    [max_origname_yr]   NVARCHAR (255) NULL,
    [min_origname_yr]   NVARCHAR (255) NULL,
    [vol_year]          FLOAT (53)     NULL,
    [vol_acc_year]      FLOAT (53)     NULL,
    [total_value_year]  MONEY          NULL,
    [max_value_year]    MONEY          NULL,
    [min_value_year]    MONEY          NULL,
    [ave_value_year]    MONEY          NULL,
    [RefusedByRBSG]     BIT            DEFAULT ((0)) NOT NULL,
    [RefusedByReward]   BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [pk_OIN] PRIMARY KEY CLUSTERED ([OIN] ASC)
);

