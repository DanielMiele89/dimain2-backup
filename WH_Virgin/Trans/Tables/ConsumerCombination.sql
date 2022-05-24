CREATE TABLE [Trans].[ConsumerCombination] (
    [ConsumerCombinationID]  INT          IDENTITY (1, 1) NOT NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [IsHighVariance]         BIT          NOT NULL,
    [IsUKSpend]              BIT          CONSTRAINT [DF_Trans_ConsumerCombination_IsUKSpend] DEFAULT ((1)) NOT NULL,
    [PaymentGatewayStatusID] TINYINT      CONSTRAINT [DF_Trans_ConsumerCombination_PaymentGatewayStatusID] DEFAULT ((0)) NOT NULL,
    [ModifiedDate]           DATETIME     DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_Trans_ConsumerCombination] PRIMARY KEY CLUSTERED ([ConsumerCombinationID] ASC)
);




GO
CREATE NONCLUSTERED INDEX [ix_Stuff2]
    ON [Trans].[ConsumerCombination]([IsHighVariance] ASC, [PaymentGatewayStatusID] ASC)
    INCLUDE([ConsumerCombinationID], [MID], [Narrative], [LocationCountry], [MCCID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_stuff8]
    ON [Trans].[ConsumerCombination]([MCCID] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff3]
    ON [Trans].[ConsumerCombination]([MID] ASC, [Narrative] ASC, [LocationCountry] ASC, [MCCID] ASC, [IsHighVariance] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID]) WITH (FILLFACTOR = 80);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff4]
    ON [Trans].[ConsumerCombination]([MID] ASC, [LocationCountry] ASC, [MCCID] ASC)
    INCLUDE([ConsumerCombinationID], [PaymentGatewayStatusID], [IsHighVariance], [Narrative]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff5]
    ON [Trans].[ConsumerCombination]([BrandID] ASC, [PaymentGatewayStatusID] ASC)
    INCLUDE([MID], [MCCID]);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff6]
    ON [Trans].[ConsumerCombination]([MID] ASC, [MCCID] ASC)
    INCLUDE([PaymentGatewayStatusID], [BrandID]);


GO
CREATE TRIGGER [Trans].[Trigger_ConsumerCombination_ModifiedDate]
ON [WH_Virgin].[Trans].[ConsumerCombination]
AFTER UPDATE AS
	UPDATE [WH_Virgin].[Trans].[ConsumerCombination]
	SET [WH_Virgin].[Trans].[ConsumerCombination].[ModifiedDate] = GETDATE()
	WHERE [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID] IN (SELECT [WH_Virgin].[Trans].[ConsumerCombination].[ConsumerCombinationID] FROM inserted);