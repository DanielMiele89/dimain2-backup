﻿CREATE TABLE [InsightArchive].[RBSMissingMatchDetail] (
    [MatchID]                INT            NOT NULL,
    [PublisherID]            INT            NOT NULL,
    [FanID]                  INT            NOT NULL,
    [TranDate]               DATE           NULL,
    [AddedDate]              DATE           NULL,
    [Spend]                  SMALLMONEY     NOT NULL,
    [Investment]             SMALLMONEY     NULL,
    [RetailerID]             INT            NULL,
    [CardHolderPresentData]  VARCHAR (1)    NULL,
    [OutletChannel]          TINYINT        NOT NULL,
    [IronOfferID]            INT            NULL,
    [RetailerCashback]       SMALLMONEY     NOT NULL,
    [DealManagedBy]          VARCHAR (100)  NOT NULL,
    [RewardShare]            DECIMAL (5, 2) NULL,
    [PublisherShare]         DECIMAL (5, 2) NULL,
    [SpendStretchAmount]     MONEY          NULL,
    [MonthlyExcludeID]       INT            NULL,
    [RetailerIsOnline]       BIT            NOT NULL,
    [OutletID]               INT            NOT NULL,
    [PanID]                  INT            NULL,
    [QuidcoSourceUID]        VARCHAR (20)   NULL,
    [SchemeMembershipTypeID] TINYINT        NULL,
    [UpstreamMatchID]        INT            NULL,
    PRIMARY KEY CLUSTERED ([MatchID] ASC)
);

