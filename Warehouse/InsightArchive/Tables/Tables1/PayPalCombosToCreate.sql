CREATE TABLE [InsightArchive].[PayPalCombosToCreate] (
    [SecondaryCombinationid] INT          NOT NULL,
    [ConsumerCombinationID]  INT          NULL,
    [PaypalComboID]          INT          NOT NULL,
    [BrandMIDID]             INT          NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [IsHighVariance]         INT          NOT NULL,
    [IsUKSpend]              BIT          NOT NULL,
    [PaymentGatewayStatusID] TINYINT      NOT NULL,
    [IsCreditOrigin]         BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([SecondaryCombinationid] ASC)
);

