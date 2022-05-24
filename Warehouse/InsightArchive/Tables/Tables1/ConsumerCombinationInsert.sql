CREATE TABLE [InsightArchive].[ConsumerCombinationInsert] (
    [ID]                     INT          NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [IsHighVariance]         BIT          NOT NULL,
    [SuggestedBrandID]       SMALLINT     NULL,
    [MatchType]              TINYINT      NULL,
    [AcquirerID]             TINYINT      NOT NULL,
    [MatchCount]             INT          NULL,
    [BrandProbability]       FLOAT (53)   NULL,
    [IsUKSpend]              BIT          NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [PaymentGatewayStatusID] TINYINT      NOT NULL,
    [ConsumerCombinationID]  INT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

