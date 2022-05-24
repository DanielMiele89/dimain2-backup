CREATE TABLE [Trans].[ConsumerCombination_20220427] (
    [ConsumerCombinationID]  INT           NOT NULL,
    [BrandID]                SMALLINT      NOT NULL,
    [MID]                    VARCHAR (50)  NOT NULL,
    [Narrative]              VARCHAR (150) NULL,
    [LocationCountry]        VARCHAR (3)   NOT NULL,
    [MCCID]                  SMALLINT      NOT NULL,
    [IsHighVariance]         BIT           NOT NULL,
    [IsUKSpend]              BIT           CONSTRAINT [DF_Trans_ConsumerCombination_IsUKSpend_20220427] DEFAULT ((1)) NOT NULL,
    [PaymentGatewayStatusID] TINYINT       CONSTRAINT [DF_Trans_ConsumerCombination_PaymentGatewayStatusID_20220427] DEFAULT ((0)) NOT NULL,
    [ModifiedDate]           DATETIME      DEFAULT (getdate()) NULL,
    [OriginatorID]           INT           NULL,
    CONSTRAINT [PK_Trans_ConsumerCombination_20220427] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC) WITH (FILLFACTOR = 90)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [Trans].[ConsumerCombination_20220427]([IsHighVariance] ASC, [PaymentGatewayStatusID] ASC)
    INCLUDE([ConsumerCombinationID], [MID], [Narrative], [LocationCountry], [MCCID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [Trans].[ConsumerCombination_20220427]([MID] ASC, [Narrative] ASC, [LocationCountry] ASC, [MCCID] ASC, [IsHighVariance] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff4]
    ON [Trans].[ConsumerCombination_20220427]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID], [IsHighVariance], [Narrative]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff5]
    ON [Trans].[ConsumerCombination_20220427]([BrandID] ASC, [PaymentGatewayStatusID] ASC)
    INCLUDE([MID], [MCCID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff6]
    ON [Trans].[ConsumerCombination_20220427]([MID] ASC, [MCCID] ASC)
    INCLUDE([PaymentGatewayStatusID], [BrandID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [ix_stuff8]
    ON [Trans].[ConsumerCombination_20220427]([MCCID] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID]) WITH (FILLFACTOR = 90);

