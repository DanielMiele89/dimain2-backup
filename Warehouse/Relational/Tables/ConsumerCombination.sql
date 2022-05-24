CREATE TABLE [Relational].[ConsumerCombination] (
    [ConsumerCombinationID]  INT          IDENTITY (1, 1) NOT NULL,
    [BrandMIDID]             INT          NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [IsHighVariance]         BIT          NOT NULL,
    [IsUKSpend]              BIT          CONSTRAINT [DF_Relational_ConsumerCombination_IsUKSpend] DEFAULT ((1)) NOT NULL,
    [PaymentGatewayStatusID] TINYINT      CONSTRAINT [DF_Relational_ConsumerCombination_PaymentGatewayStatusID] DEFAULT ((0)) NOT NULL,
    [IsCreditOrigin]         BIT          CONSTRAINT [DF_Relational_ConsumerCombination_IsCreditOrigin] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Relational_ConsumerCombination] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [FK_ConsumerCombination_Brand] FOREIGN KEY ([BrandID]) REFERENCES [Relational].[Brand] ([BrandID])
);


GO
CREATE NONCLUSTERED INDEX [IX_Relational_ConsumerCombination]
    ON [Relational].[ConsumerCombination]([BrandMIDID] ASC, [MCCID] ASC, [OriginatorID] ASC) WITH (FILLFACTOR = 90)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_NCL_Relational_ConsumerCombination_Matching]
    ON [Relational].[ConsumerCombination]([IsHighVariance] ASC, [ConsumerCombinationID] ASC, [MID] ASC, [Narrative] ASC, [LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC) WITH (FILLFACTOR = 90)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_NCL_ConsumerCombination_PaymentGateway]
    ON [Relational].[ConsumerCombination]([PaymentGatewayStatusID] ASC)
    INCLUDE([BrandID], [MID], [LocationCountry], [MCCID], [OriginatorID])
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [IX_NCL_ConsumerCombination_MIDLocMCC]
    ON [Relational].[ConsumerCombination]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC, [OriginatorID] ASC)
    INCLUDE([BrandID], [PaymentGatewayStatusID], [Narrative], [IsHighVariance]) WITH (FILLFACTOR = 90)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_BrandID]
    ON [Relational].[ConsumerCombination]([BrandID] ASC)
    INCLUDE([ConsumerCombinationID], [IsUKSpend]) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_MID]
    ON [Relational].[ConsumerCombination]([MID] ASC)
    INCLUDE([ConsumerCombinationID], [Narrative]) WITH (FILLFACTOR = 95)
    ON [Warehouse_Indexes];


GO
CREATE NONCLUSTERED INDEX [ix_MIDI]
    ON [Relational].[ConsumerCombination]([LocationCountry] ASC, [MID] ASC, [MCCID] ASC, [OriginatorID] ASC, [Narrative] ASC)
    INCLUDE([IsHighVariance], [PaymentGatewayStatusID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

