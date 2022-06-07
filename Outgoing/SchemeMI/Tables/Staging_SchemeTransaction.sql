CREATE TABLE [SchemeMI].[Staging_SchemeTransaction] (
    [ID]                            INT           IDENTITY (1, 1) NOT NULL,
    [MatchID]                       INT           NOT NULL,
    [FanID]                         INT           NOT NULL,
    [Spend]                         MONEY         NOT NULL,
    [Earnings]                      MONEY         NOT NULL,
    [AddedDate]                     DATE          NOT NULL,
    [BrandID]                       SMALLINT      NOT NULL,
    [OfferAboveBase]                BIT           NULL,
    [TranWeekID]                    SMALLINT      NULL,
    [TranMonthID]                   SMALLINT      NULL,
    [IsEarn]                        BIT           CONSTRAINT [DF_Staging_SchemeTransaction_IsEarn] DEFAULT ((1)) NOT NULL,
    [SpendAtBaseCust]               INT           NULL,
    [SpendAboveBaseCust]            INT           NULL,
    [EarnAtBaseCust]                INT           NULL,
    [EarnAboveBaseCust]             INT           NULL,
    [EarnCust]                      INT           NULL,
    [AddedDateTime]                 SMALLDATETIME NULL,
    [IronOfferID]                   INT           NULL,
    [RBSFunded]                     TINYINT       CONSTRAINT [DF_schememi_staging_schemeTransaction_RBSFunded] DEFAULT ((1)) NOT NULL,
    [SpendAtBase]                   MONEY         NULL,
    [SpendAboveBase]                MONEY         NULL,
    [EarningsAtBase]                MONEY         NULL,
    [EarningsAboveBase]             MONEY         NULL,
    [GenderID]                      TINYINT       NULL,
    [AgeBandID]                     TINYINT       NULL,
    [BankID]                        TINYINT       NULL,
    [RainbowID]                     TINYINT       NULL,
    [ChannelPreferenceID]           TINYINT       NULL,
    [ActivationMethodID]            TINYINT       NULL,
    [AdditionalCashbackAwardTypeID] TINYINT       NOT NULL,
    [PaymentMethodID]               TINYINT       NOT NULL,
    [RowHash]                       INT           NOT NULL,
    [BatchID]                       INT           DEFAULT ((0)) NULL,
    [IsRBS]                         BIT           NULL,
    CONSTRAINT [PK_SchemeMI_Staging_SchemeTransaction] PRIMARY KEY CLUSTERED ([ID] ASC) WITH (DATA_COMPRESSION = PAGE)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [ix_Stuff]
    ON [SchemeMI].[Staging_SchemeTransaction]([AddedDate] ASC, [FanID] ASC, [MatchID] ASC, [AdditionalCashbackAwardTypeID] ASC)
    INCLUDE([RowHash]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

