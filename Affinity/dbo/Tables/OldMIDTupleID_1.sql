CREATE TABLE [dbo].[OldMIDTupleID] (
    [ConsumerCombinationID]  INT              NOT NULL,
    [BrandMIDID]             INT              NULL,
    [BrandID]                SMALLINT         NOT NULL,
    [MID]                    VARCHAR (50)     NOT NULL,
    [Narrative]              VARCHAR (50)     NOT NULL,
    [LocationCountry]        VARCHAR (3)      NOT NULL,
    [MCCID]                  SMALLINT         NOT NULL,
    [OriginatorID]           VARCHAR (11)     NOT NULL,
    [IsHighVariance]         BIT              NOT NULL,
    [IsUKSpend]              BIT              NOT NULL,
    [PaymentGatewayStatusID] TINYINT          NOT NULL,
    [IsCreditOrigin]         BIT              NOT NULL,
    [ProxyMIDTupleID]        VARBINARY (8000) NULL,
    [ProxyMID]               NVARCHAR (MAX)   NULL,
    [MCC]                    VARCHAR (4)      NULL
);

