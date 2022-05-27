CREATE TABLE [Staging].[SSIS_matchedConsumerCombination] (
    [ID]                                 INT            IDENTITY (1, 1) NOT NULL,
    [ConsumerCombinationID]              INT            NULL,
    [BrandMIDID]                         INT            NULL,
    [BrandID]                            SMALLINT       NULL,
    [MID]                                VARCHAR (50)   NULL,
    [Narrative]                          VARCHAR (50)   NULL,
    [LocationCountry]                    VARCHAR (3)    NULL,
    [MCCID]                              SMALLINT       NULL,
    [OriginatorID]                       VARCHAR (11)   NULL,
    [IsHighVariance]                     BIT            NULL,
    [IsUKSpend]                          BIT            NULL,
    [PaymentGatewayStatusID]             TINYINT        NULL,
    [TrimedCleanedNarrative]             VARCHAR (6)    NULL,
    [CleanedNarrative]                   VARCHAR (8000) NULL,
    [TrimedCleanedNarrative (1)]         VARCHAR (50)   NULL,
    [_Similarity]                        REAL           NULL,
    [_Confidence]                        REAL           NULL,
    [_Similarity_TrimedCleanedNarrative] REAL           NULL
);

