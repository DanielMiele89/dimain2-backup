CREATE TABLE [Zoe].[ConsumerCombinations] (
    [ConsumerCombinationID]  INT          NOT NULL,
    [BrandMIDID]             INT          NULL,
    [BrandID]                SMALLINT     NOT NULL,
    [MID]                    VARCHAR (50) NOT NULL,
    [Narrative]              VARCHAR (50) NOT NULL,
    [LocationCountry]        VARCHAR (3)  NOT NULL,
    [MCCID]                  SMALLINT     NOT NULL,
    [OriginatorID]           VARCHAR (11) NOT NULL,
    [IsHighVariance]         BIT          NOT NULL,
    [IsUKSpend]              BIT          NOT NULL,
    [PaymentGatewayStatusID] TINYINT      NOT NULL,
    [IsCreditOrigin]         BIT          NOT NULL,
    [MerchantZip]            NVARCHAR (9) NULL,
    [MCC]                    VARCHAR (4)  NULL,
    [BrandName]              VARCHAR (50) NULL,
    [LocationAddress]        VARCHAR (50) NULL
);


GO
CREATE CLUSTERED INDEX [cx_Stuff]
    ON [Zoe].[ConsumerCombinations]([ConsumerCombinationID] ASC);

